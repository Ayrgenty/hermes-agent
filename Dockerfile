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

# Установка менеджера uv и зависимостей Python
RUN curl -fsSL https://astral.sh | sh && \
    export PATH="/root/.local/bin:$PATH" && \
    uv pip install --system -e .

# Создаем папку для данных (которую мы примонтируем в Railway)
RUN mkdir -p /opt/data

EXPOSE 3000

# Запуск приложения
CMD ["python", "-m", "hermes_agent.main"]
