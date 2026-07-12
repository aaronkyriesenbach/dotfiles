# Python Coverage Guide

## Runners

| Test runner | Coverage tool | Coverage command |
|---|---|---|
| pytest | `pytest-cov` | `pytest --cov=src --cov-report=term --cov-report=html` |
| unittest | `coverage.py` | `coverage run -m unittest && coverage report` |
| tox | `pytest-cov` or `coverage.py` (configured in `tox.ini`) | `tox` |

## Detection

Check `pyproject.toml`, `setup.cfg`, or `tox.ini` for:
- `[tool.pytest.ini_options]` → pytest
- `[tool.coverage.*]` → coverage.py
- `[tox]` → tox

## Coverage output

| Tool | Output format | Default location |
|---|---|---|
| coverage.py | `.coverage` (SQLite), XML, HTML, JSON, text | `.coverage`, `htmlcov/` |
| pytest-cov | Same as coverage.py (it wraps it) | Same |

## Gotchas

- **`coverage.py` needs `source` or `include` configured** or it measures everything in the current directory (including venvs and test files). Check `[tool.coverage.run]` in `pyproject.toml`.
- **`pytest-cov` uses `--cov=<package>`** — if omitted, it may only measure test files.
- **`conftest.py` files are not tracked** — coverage tools treat them as test infrastructure.
- **`__init__.py` files often show 100% coverage** even when the module is empty — ignore them.
- **Async tests (pytest-asyncio)** report coverage normally, but `pytest-cov` may miss lines hit in async context if using an old version.

## Finding untested files

```bash
for f in $(find src -name '*.py' | grep -v '__pycache__\|test_\|_test\.py\|conftest\|__init__'); do
  dir=$(dirname "$f")
  base=$(basename "$f" .py)
  if ! find "$dir" tests -name "test_${base}.py" -o -name "${base}_test.py" 2>/dev/null | grep -q .; then
    echo "NO TEST: $f"
  fi
done
```