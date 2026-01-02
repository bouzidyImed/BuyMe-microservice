FROM python:3.11-slim
WORKDIR /app
COPY . /app
RUN if [ -f /app/requirements.txt ]; then pip install --no-cache-dir -r /app/requirements.txt; else echo "No requirements.txt, skipping pip install"; fi
ENV PYTHONUNBUFFERED=1
EXPOSE 5000
CMD ["python","app.py"]
