FROM python:3.14-slim

WORKDIR /app

COPY pyproject.toml ./
COPY src ./src
COPY app.py ./app.py

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir .

EXPOSE 8000

CMD ["python", "app.py"]
