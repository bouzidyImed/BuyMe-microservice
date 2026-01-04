FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    POETRY_VIRTUALENVS_CREATE=false

WORKDIR /app

# system deps (if needed) and cleanup to keep image small
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy project files
COPY . /app

# Install Python deps (use local relaxed requirements if present)
RUN pip install --upgrade pip setuptools wheel && \
    if [ -f requirements_local.txt ]; then pip install -r requirements_local.txt; else pip install -r requirements.txt; fi

EXPOSE 5000

ENV PORT=5000

HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD curl -f http://localhost:${PORT}/health || exit 1

CMD ["python", "app.py"]
FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Copy wheels for offline install
COPY wheels /wheels
COPY requirements.txt .

# Install dependencies from wheels
RUN pip install --no-index --find-links=/wheels -r requirements.txt

# Copy app code
COPY . .

# Expose port (if using Flask)
EXPOSE 5000

# Start service
CMD ["python", "app.py"]
