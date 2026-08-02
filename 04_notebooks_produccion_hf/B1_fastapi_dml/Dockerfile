# B1 DML inference service
# Build from monorepo root:
#   docker build -f 04_notebooks_produccion_hf/B1_fastapi_dml/Dockerfile -t causal-b1 .
# Run:
#   docker run --rm -p 8000:8000 causal-b1

FROM python:3.11-slim

WORKDIR /app

# System deps (minimal)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# B1 requirements
COPY 04_notebooks_produccion_hf/B1_fastapi_dml/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Service code (includes estimator_shim for portable unpickle — no full Serie A lib)
COPY 04_notebooks_produccion_hf/B1_fastapi_dml/app /app/app

# Default artifacts (can be overridden by volume mount)
COPY 04_notebooks_produccion_hf/B1_fastapi_dml/artifacts /app/artifacts

ENV PYTHONPATH=/app
ENV B1_ARTIFACTS_DIR=/app/artifacts
ENV PYTHONUNBUFFERED=1

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -fsS http://127.0.0.1:8000/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
