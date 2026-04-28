# ЭТАП 1: Сборка фронтенда и установка зависимостей
FROM node:22-slim AS builder

WORKDIR /app
COPY . .

# Установка зависимостей и сборка (если есть фронтенд часть)
RUN npm install && \
    if [ -d "ts/hermes-bus" ]; then cd ts/hermes-bus && npm install && npm run build; fi

# ЭТАП 2: Финальный образ
FROM python:3.11-slim

WORKDIR /app

# Установка системных зависимостей (минимум для работы)
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Копируем только необходимые файлы из сборщика
COPY --from=builder /app /app

# Установка uv и пакета в режиме Editable (чтобы модули были видны)
RUN curl -fsSL https://astral.sh/uv/install.sh | sh && \
    /root/.local/bin/uv pip install --system --no-cache .

# Добавляем текущую директорию в путь поиска модулей Python
ENV PYTHONPATH="/app:${PYTHONPATH}"

# Создаем папку для данных
RUN mkdir -p /opt/data

EXPOSE 3000

# Запуск напрямую через файл, чтобы избежать проблем с именованием модулей
CMD ["python", "hermes_agent/main.py"]
