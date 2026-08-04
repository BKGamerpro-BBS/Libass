# Project Rules — Catalog to Excel Sheet

## Architecture & Structure
- This is a **Python FastAPI** application. All backend code lives under `app/`.
- Follow the existing module layout: `api/` for endpoints, `processing/` for OCR/PDF logic, `jobs/` for async workers, `catalog/` for Excel generation, `storage/` for file I/O.
- The frontend is served from `static/` as a single-page app — do not mix backend templates with it.
- Configuration is loaded from `.env` via `app/config.py` using `python-dotenv`. Never hardcode secrets or paths.

## Python Conventions
- Use **Python 3.10+** syntax (type hints, `match` statements where appropriate).
- Follow **PEP 8** naming: `snake_case` for functions/variables, `PascalCase` for classes, `UPPER_SNAKE` for constants.
- All async endpoints must use `async def`. Blocking I/O (Tesseract, file writes) should be offloaded to the thread pool via `asyncio.to_thread()` or the job worker.
- Prefer `pathlib.Path` over `os.path` for file system operations.
- Every public function and class must have a docstring.
- Always use `asyncio.to_thread` for blocking image processing tasks in `libass_app`.

## Web & Frontend Conventions
- Prefer strict TypeScript types and modular exports across all web projects.

## Error Handling
- API endpoints must return structured error responses using FastAPI's `HTTPException`.
- Processing functions must catch and log exceptions rather than letting them crash the worker silently.
- Always validate uploaded file types (PDF, PNG, JPG, JPEG, TIFF) before processing.

## Testing
- Tests live in `tests/unit/` and `tests/integration/`.
- Use `pytest` with `pytest-asyncio` for async test cases.
- When modifying processing logic, always add or update the corresponding unit test.

## Dependencies
- Pin exact versions for critical libs (`openpyxl`, `pytesseract`). Use `>=` for framework packages.
- Do not add new dependencies without documenting the reason.

## Git & Workflow
- Write clear, imperative commit messages (e.g., "Add TIFF support to OCR pipeline").
- Do not commit `.env`, `file_store/` outputs, or `__pycache__/` directories.

## Excel Output
- Generated Excel files must include styled headers, auto-filters, and column auto-width.
- Category columns should use data validation dropdowns where possible.
- Image thumbnails embedded in cells should be resized to fit within 100×100 px.

## Docker
- The `Dockerfile` and `docker-compose.yml` must remain functional. Test container builds after dependency changes.

## Knowledge Graph & Architecture Analysis
- Graphify is integrated into `.agents/skills/graphify/SKILL.md`. Use `graphify query` or `graphify . --code-only` to analyze component relationships and dependencies across the codebase.

