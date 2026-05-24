#!/bin/bash

# =============================================================================
# Agent OS Project Update Script
# Updates an existing Agent OS project installation to match the current profile.
#
# Unlike project-install.sh (which only adds/overwrites), this script also:
#   - PRUNES files that no longer exist in the profile (orphans)
#   - BACKS UP anything it overwrites or removes (under agent-os/.backups/<ts>/)
#   - Supports --dry-run so you can preview every change before applying it
# =============================================================================

set -e

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$(pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# -----------------------------------------------------------------------------
# Default Values
# -----------------------------------------------------------------------------

VERBOSE="false"
PROFILE=""
DRY_RUN="false"
NO_PRUNE="false"
NO_BACKUP="false"

# Counters (accumulated by sync_area across all areas)
ADDED=0
UPDATED=0
UNCHANGED=0
PRUNED=0

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Update an existing Agent OS installation in the current project to match the
current profile (standards, workflows, and commands). Prunes orphaned files and
backs up anything overwritten or removed.

Options:
    --profile <name>     Update from this profile (default: from config.yml)
    --dry-run            Show what would change without modifying anything
    --no-prune           Add/update files but do NOT remove orphans
    --no-backup          Do not back up overwritten/removed files (faster, riskier)
    --verbose            Show detailed output
    -h, --help           Show this help message

Examples:
    $0 --dry-run                 # preview changes
    $0                           # apply update (with backups + pruning)
    $0 --no-prune                # additive update, keep orphans
    $0 --profile rails

For a first-time install, use project-install.sh instead.
EOF
    exit 0
}

# -----------------------------------------------------------------------------
# Argument Parsing
# -----------------------------------------------------------------------------

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --profile) PROFILE="$2"; shift 2 ;;
            --dry-run) DRY_RUN="true"; shift ;;
            --no-prune) NO_PRUNE="true"; shift ;;
            --no-backup) NO_BACKUP="true"; shift ;;
            --verbose) VERBOSE="true"; shift ;;
            -h|--help) show_help ;;
            *) print_error "Unknown option: $1"; show_help ;;
        esac
    done
}

# -----------------------------------------------------------------------------
# Validation
# -----------------------------------------------------------------------------

validate_base_installation() {
    if [[ ! -f "$BASE_DIR/config.yml" ]]; then
        print_error "Base installation config.yml not found"
        exit 1
    fi
}

validate_not_in_base() {
    if [[ "$PROJECT_DIR" == "$BASE_DIR" ]]; then
        print_error "Cannot update Agent OS in the base installation directory"
        echo ""
        echo "Navigate to your project directory first:"
        echo "  cd /path/to/your/project"
        exit 1
    fi
}

validate_existing_install() {
    if [[ ! -d "$PROJECT_DIR/agent-os" ]]; then
        print_error "No existing Agent OS installation found in this project"
        echo ""
        echo "This is the update script. For a first-time install, run:"
        echo "  $SCRIPT_DIR/project-install.sh"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Configuration (same inheritance resolution as project-install.sh)
# -----------------------------------------------------------------------------

load_configuration() {
    local config_file="$BASE_DIR/config.yml"
    local default_profile=$(get_yaml_value "$config_file" "default_profile" "default")
    EFFECTIVE_PROFILE="${PROFILE:-$default_profile}"

    if [[ ! -d "$BASE_DIR/profiles/$EFFECTIVE_PROFILE" ]]; then
        print_error "Profile not found: $EFFECTIVE_PROFILE"
        exit 1
    fi

    local chain_result=$(get_profile_inheritance_chain "$config_file" "$EFFECTIVE_PROFILE" "$BASE_DIR/profiles")

    if [[ "$chain_result" == CIRCULAR:* ]]; then
        print_error "Circular dependency in profile inheritance chain: ${chain_result#CIRCULAR:}"
        exit 1
    fi
    if [[ "$chain_result" == NOTFOUND:* ]]; then
        print_error "Profile not found in inheritance chain: ${chain_result#NOTFOUND:}"
        exit 1
    fi

    INHERITANCE_CHAIN="$chain_result"
    AGENT_OS_VERSION=$(get_yaml_value "$config_file" "version" "unknown")

    print_verbose "Profile: $EFFECTIVE_PROFILE"
    print_verbose "Inheritance chain: $(echo "$INHERITANCE_CHAIN" | tr '\n' ' ')"
}

# -----------------------------------------------------------------------------
# Manifest builders — emit "relative_path|absolute_source_path" lines.
# Later profiles in the chain override earlier ones (dedup keeps last).
# -----------------------------------------------------------------------------

# Walk the inheritance chain for a profile subdir (standards or workflows).
build_profile_manifest() {
    local subdir="$1"
    local out="$2"
    : > "$out"

    while IFS= read -r profile_name; do
        [[ -z "$profile_name" ]] && continue
        local src="$BASE_DIR/profiles/$profile_name/$subdir"
        [[ ! -d "$src" ]] && continue

        while IFS= read -r -d '' file; do
            local rel="${file#$src/}"
            grep -v "^${rel}|" "$out" > "${out}.tmp" 2>/dev/null || true
            mv "${out}.tmp" "$out"
            echo "${rel}|${file}" >> "$out"
        done < <(find "$src" -name "*.md" -type f ! -path "*/.backups/*" -print0 2>/dev/null)
    done <<< "$INHERITANCE_CHAIN"
}

# Base commands plus profile command overrides (README.md excluded).
build_commands_manifest() {
    local out="$1"
    : > "$out"

    local base="$BASE_DIR/commands/agent-os"
    if [[ -d "$base" ]]; then
        for f in "$base"/*.md; do
            [[ -f "$f" ]] || continue
            echo "$(basename "$f")|${f}" >> "$out"
        done
    fi

    while IFS= read -r profile_name; do
        [[ -z "$profile_name" ]] && continue
        local src="$BASE_DIR/profiles/$profile_name/commands"
        [[ ! -d "$src" ]] && continue

        while IFS= read -r -d '' file; do
            local rel="${file#$src/}"
            [[ "$(basename "$rel")" == "README.md" ]] && continue
            grep -v "^${rel}|" "$out" > "${out}.tmp" 2>/dev/null || true
            mv "${out}.tmp" "$out"
            echo "${rel}|${file}" >> "$out"
        done < <(find "$src" -name "*.md" -type f ! -path "*/.backups/*" -print0 2>/dev/null)
    done <<< "$INHERITANCE_CHAIN"
}

# -----------------------------------------------------------------------------
# Backup + sync
# -----------------------------------------------------------------------------

backup_existing() {
    # $1 = existing file (absolute), $2 = area label
    [[ "$NO_BACKUP" == "true" || "$DRY_RUN" == "true" ]] && return 0
    local rel="${1#$PROJECT_DIR/}"
    local bdest="$BACKUP_ROOT/$rel"
    ensure_dir "$(dirname "$bdest")"
    cp "$1" "$bdest"
}

# Reconcile a destination tree against a manifest of desired files.
# $1 = area label, $2 = dest dir, $3 = manifest file
sync_area() {
    local area="$1"
    local dest_dir="$2"
    local manifest="$3"

    print_status "Reconciling $area..."
    [[ "$DRY_RUN" != "true" ]] && ensure_dir "$dest_dir"

    # Add / update from the manifest
    while IFS='|' read -r rel src; do
        [[ -z "$rel" ]] && continue
        local dest="$dest_dir/$rel"
        if [[ ! -e "$dest" ]]; then
            echo "  + add     $rel"
            (( ADDED++ )) || true
            if [[ "$DRY_RUN" != "true" ]]; then
                ensure_dir "$(dirname "$dest")"
                cp "$src" "$dest"
            fi
        elif ! cmp -s "$src" "$dest"; then
            echo "  ~ update  $rel"
            (( UPDATED++ )) || true
            backup_existing "$dest" "$area"
            if [[ "$DRY_RUN" != "true" ]]; then
                cp "$src" "$dest"
            fi
        else
            (( UNCHANGED++ )) || true
            print_verbose "  = same    $rel"
        fi
    done < "$manifest"

    # Prune orphans (.md files in dest not present in the manifest)
    if [[ "$NO_PRUNE" != "true" ]]; then
        while IFS= read -r -d '' file; do
            local rel="${file#$dest_dir/}"
            if ! grep -q "^${rel}|" "$manifest"; then
                echo "  - prune   $rel"
                (( PRUNED++ )) || true
                backup_existing "$file" "$area"
                if [[ "$DRY_RUN" != "true" ]]; then
                    rm -f "$file"
                fi
            fi
        done < <(find "$dest_dir" -name "*.md" -type f ! -path "*/.backups/*" -print0 2>/dev/null)
    fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
    print_section "Agent OS Project Update"

    parse_arguments "$@"
    validate_not_in_base
    validate_base_installation
    validate_existing_install
    load_configuration

    echo ""
    print_status "Configuration:"
    echo "  Profile:    $EFFECTIVE_PROFILE"
    echo "  Version:    $AGENT_OS_VERSION"
    echo "  Dry run:    $DRY_RUN"
    echo "  Prune:      $([[ "$NO_PRUNE" == "true" ]] && echo "off" || echo "on")"
    echo "  Backups:    $([[ "$NO_BACKUP" == "true" ]] && echo "off" || echo "on")"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo ""
        print_warning "DRY RUN — no files will be changed"
    fi

    # Backup location for this run (only created lazily when something is backed up)
    BACKUP_ROOT="$PROJECT_DIR/agent-os/.backups/$(date +%Y%m%d-%H%M%S)"

    # Temp manifests
    local std_manifest=$(mktemp)
    local wf_manifest=$(mktemp)
    local cmd_manifest=$(mktemp)
    trap "rm -f '$std_manifest' '$wf_manifest' '$cmd_manifest' '${std_manifest}.tmp' '${wf_manifest}.tmp' '${cmd_manifest}.tmp'" EXIT

    build_profile_manifest "standards" "$std_manifest"
    build_profile_manifest "workflows" "$wf_manifest"
    build_commands_manifest "$cmd_manifest"

    echo ""
    sync_area "standards" "$PROJECT_DIR/agent-os/standards" "$std_manifest"
    echo ""
    sync_area "workflows" "$PROJECT_DIR/agent-os/workflows" "$wf_manifest"
    echo ""
    sync_area "commands"  "$PROJECT_DIR/.claude/commands/agent-os" "$cmd_manifest"

    # Regenerate the standards index against the reconciled tree
    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
        print_status "Standards index would be regenerated (skipped in dry run)"
    else
        print_status "Regenerating standards index..."
        regenerate_standards_index "$PROJECT_DIR/agent-os/standards"
        print_success "index.yml: $INDEX_ENTRY_COUNT entries ($INDEX_NEW_COUNT need descriptions)"
        # Record the version we updated to
        echo "$AGENT_OS_VERSION" > "$PROJECT_DIR/agent-os/.agent-os-version"
    fi

    # Summary
    echo ""
    print_section "Update Summary"
    echo "  Added:     $ADDED"
    echo "  Updated:   $UPDATED"
    echo "  Unchanged: $UNCHANGED"
    echo "  Pruned:    $PRUNED"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo ""
        print_warning "Dry run complete — re-run without --dry-run to apply."
    else
        if [[ "$NO_BACKUP" != "true" && -d "$BACKUP_ROOT" ]]; then
            echo ""
            print_status "Backups of overwritten/pruned files: ${BACKUP_ROOT#$PROJECT_DIR/}"
        fi
        echo ""
        print_success "Agent OS update complete!"
        if [[ "$INDEX_NEW_COUNT" -gt 0 ]]; then
            echo ""
            echo "Next step: run /index-standards to describe $INDEX_NEW_COUNT new standard(s)."
        fi
    fi
    echo ""
}

main "$@"
