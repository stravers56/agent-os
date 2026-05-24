# Database Conventions

## Engine Selection

- **Default:** SQLite (file-based, simple, single-user) or PostreSQL
- **When SQLite is not appropriate:** PostgreSQL
  - Multi-user concurrent access
  - High data volume
  - Network-accessible database needed

## SQLite

- Store `.db` file in `$icloudpath/databases`
- Use WAL mode for better concurrent read performance
- Keep schema migrations in a `migrations/` directory

## PostgreSQL

### When to Use

- Shared or multi-user applications
- High write concurrency or large datasets (>1 GB or >1M rows)
- Need for advanced types (JSONB, arrays, ranges, geometric, full-text search)
- Network-accessible database required
- Strict referential integrity and ACID guarantees across complex transactions

### Version & Setup

- Target PostgreSQL 16 or later (17 preferred for new projects)
- Run locally via Homebrew (`brew install postgresql@17`) or Docker
- Store connection strings in environment variables, never in code
- Use macOS Keychain for credentials in personal projects — reference by service name in code

### Default Server (cio-pg-db)

- **Host:** `cio-pg-db.postgres.database.azure.com` (Azure Flexible Server)
- **Admin login:** `cioadmin` — credentials in BitWarden Secrets, exported at shell startup by `/Users/local/scripts/apikeys.zsh`
- **Per-project convention:** each project gets its own database (slug-named) and a least-privilege `<slug>_app` role — never share a database or use `cioadmin` for app connections
- **Connection string:** export as `<SLUG>_DATABASE_URL` per project; never hard-code

### Connection & Drivers

- **Python:** `psycopg` (v3) for sync, `asyncpg` for async — avoid the legacy `psycopg2`
- **Rust:** `sqlx` (compile-time checked queries) or `tokio-postgres` for async
- **JavaScript/Node:** `postgres` (porsager) or `pg`
- Always use a connection pool (`pgbouncer` for production; built-in pools for local dev)
- Set explicit `statement_timeout` and `idle_in_transaction_session_timeout`

### Schema Conventions

- Database, schema, table, and column names: `snake_case`
- Table names: plural (`users`, `orders`); join tables: `users_roles`
- Primary keys: `id` as `bigint generated always as identity` (or `uuid` with `gen_random_uuid()` when distributed)
- Foreign keys: `<referenced_table_singular>_id` (e.g., `user_id`)
- Timestamps: `created_at`, `updated_at` as `timestamptz` (never `timestamp` without time zone)
- Booleans: prefix with `is_`, `has_`, or `can_`
- Use `NOT NULL` by default; add nullability only when semantically meaningful
- Prefer `text` over `varchar(n)` unless a hard length limit is enforced
- Use `jsonb` (not `json`) for structured payloads; index with GIN when queried
- Use `numeric` for money (never `float`/`real`/`double precision`)
- Use `citext` for case-insensitive string columns (e.g., email)

### Indexing

- Index every foreign key column
- Add composite indexes matching common `WHERE` + `ORDER BY` patterns (leftmost-prefix rule)
- Use partial indexes for sparse predicates (`WHERE deleted_at IS NULL`)
- Use `GIN` for `jsonb`, arrays, and full-text search (`tsvector`)
- Drop unused indexes — check `pg_stat_user_indexes` before assuming

### Queries

- Always use parameterized queries (`$1`, `$2`) — never string concatenation or f-strings
- Use `RETURNING` clauses on `INSERT`/`UPDATE`/`DELETE` to avoid extra round-trips
- Prefer CTEs (`WITH`) for readability; switch to subqueries only when the planner needs the freedom
- Use `EXPLAIN (ANALYZE, BUFFERS)` to validate query plans on real data
- Avoid `SELECT *` in application code; list columns explicitly

### Migrations

- Keep migrations in a `migrations/` directory, numbered sequentially (`001_init.sql`, `002_add_users.sql`)
- One logical change per migration; never edit a committed migration — write a new one
- All migrations must be transactional (`BEGIN; ... COMMIT;`) unless creating indexes concurrently
- Use `CREATE INDEX CONCURRENTLY` for indexes on large tables in production
- Tools: `sqlx migrate` (Rust), `alembic` (Python), `node-pg-migrate` (JS)

### Transactions & Concurrency

- Default isolation: `READ COMMITTED`; use `REPEATABLE READ` or `SERIALIZABLE` only when needed
- Keep transactions short — never hold one open across user input or external API calls
- Use `SELECT ... FOR UPDATE` for row-level locking; `SKIP LOCKED` for work-queue patterns
- Handle serialization failures (SQLSTATE `40001`) with retry logic

### Security

- Application connects as a least-privileged role — never as `postgres` superuser
- Grant only the privileges needed (`SELECT`, `INSERT`, `UPDATE`, `DELETE` on specific tables)
- Use Row-Level Security (RLS) for multi-tenant data isolation
- Require TLS for any network connection (`sslmode=require` minimum, `verify-full` preferred)
- Rotate credentials regularly; store in Keychain or a secrets manager

### Backup & Maintenance

- Logical backups: `pg_dump -Fc` (custom format) for portability
- Physical backups: `pg_basebackup` + WAL archiving for point-in-time recovery
- Run `VACUUM ANALYZE` after large bulk loads
- Monitor bloat with `pg_stat_user_tables`; reindex periodically with `REINDEX CONCURRENTLY`

### Anti-Patterns to Avoid

- String-concatenated SQL (injection risk)
- Storing JSON when a relational schema fits
- Using `timestamp` instead of `timestamptz`
- Indexes on every column "just in case"
- Long-running transactions that block VACUUM
- ORMs that hide the generated SQL — always know what query is running
