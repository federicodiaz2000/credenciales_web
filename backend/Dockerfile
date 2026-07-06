FROM python:3.12-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PORT=8000
ENV APP_MODE=release

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

EXPOSE 8000

CMD ["sh", "-c", "if [ \"${APP_MODE:-release}\" = \"debug\" ]; then uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000} --reload --log-level debug; else uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000} --log-level info; fi"]
