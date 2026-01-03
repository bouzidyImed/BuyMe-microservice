FROM python:3.11-slim
WORKDIR /app

# Copy requirements first for better layer caching
COPY requirements.txt /app/requirements.txt

# Optional local wheelhouse (populate `customer-segmentation-service/wheels/` in CI to enable offline installs)
COPY wheels /wheels

RUN if [ -f /app/requirements.txt ]; then \
			if [ -d /wheels ] && [ "$(ls -A /wheels)" ]; then \
				pip install --no-cache-dir --no-index --find-links=/wheels -r /app/requirements.txt; \
			else \
				pip install --no-cache-dir -r /app/requirements.txt; \
			fi; \
		else \
			echo "No requirements.txt, skipping pip install"; \
		fi

# Copy application sources after installing dependencies to leverage Docker layer cache
COPY . /app

ENV PYTHONUNBUFFERED=1
EXPOSE 5000
CMD ["python","app.py"]
