# Вихідне Python середовище
FROM python:3.11-slim

# Уникаємо питань при встановленні бібліотек
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Створення директорії для коду
WORKDIR /app

# Копіюємо файли проєкту
COPY . .

# Встановлення залежностей
RUN pip install --no-cache-dir -r requirements.txt

# Створення директорії для моделей (на всяк випадок)
RUN mkdir -p models

# Відкриваємо порт (за замовчуванням uvicorn — 8000)
EXPOSE 8000

# Команда запуску FastAPI
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
