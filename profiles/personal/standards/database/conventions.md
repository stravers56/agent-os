# Database Conventions

## Engine Selection

- **Default:** SQLite (file-based, simple, single-user)
- **When SQLite is not appropriate:** MySQL
  - Multi-user concurrent access
  - High data volume
  - Network-accessible database needed

## SQLite

- Store `.db` file in the project directory
- Use WAL mode for better concurrent read performance
- Keep schema migrations in a `migrations/` directory

## MySQL

- Use for shared/multi-user applications
- Prefer InnoDB engine
- Use parameterized queries — never string concatenation
