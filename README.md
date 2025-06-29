# SQL-скрипт системы аудита пользователей

## 📌 Содержание скрипта

### 1. Функция логирования изменений log_user_changes()
### 2. Триггер для таблицы users users_update_trigger
### 3. Функция экспорта данных export_daily_user_changes()
### 4. Настройка планировщика cron.schedule

## 🔧 Технические характеристики

| Компонент        | Описание                                                                 |
|------------------|--------------------------------------------------------------------------|
| **Отслеживаемые поля** | `name`, `email`, `role`                                                  |
| **Формат экспорта**    | CSV с заголовками                                                       |
| **Периодичность**      | Ежедневно в `3:00 UTC`                                                  |
| **Локация файлов**     | `/tmp/users_audit_export_YYYY_MM_DD.csv`                              |
| **Доп. информация**    | Фиксируется время изменения, сохраняются старые значения |

## 🚀 Как использовать

1. Выполните весь скрипт в вашей PostgreSQL БД.
2. Произведите изменения в таблице `users`.
3. Проверьте таблицу `users_audit` на наличие записей.
4. Дождитесь выполнения задания cron или запустите вручную:

   ```sql
   SELECT export_daily_user_changes();
   ```

##  Схемы таблиц: 

 ```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name TEXT,
    email TEXT,
    role TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users_audit (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by TEXT,
    field_changed TEXT,
    old_value TEXT,
    new_value TEXT
);
  ```