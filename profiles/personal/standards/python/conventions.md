# Python Conventions

## Environment

- Always use `uv` to run Python in a venv
- Venv lives in the project directory
- Projects location: `/Users/local/python/`

## Performance

- Use multithreading when it improves speed/performance
- Default to threading for I/O-bound tasks
- Use multiprocessing for CPU-bound tasks

## Project Structure

```
project-name/
├── .venv/           # uv-managed virtual environment
├── pyproject.toml   # Project config
├── src/             # Source code
└── tests/           # Test files
```

## When to Use Python

- Scripting and single-file tasks
- Automation and data processing
- When in `/Users/local/python/` directory
