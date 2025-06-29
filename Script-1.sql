CREATE OR REPLACE FUNCTION log_user_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- Проверяем, изменилось ли поле name
    IF NEW.name IS DISTINCT FROM OLD.name THEN
        INSERT INTO users_audit (user_id, changed_by, field_changed, old_value, new_value)
        VALUES (NEW.id, current_user, 'name', OLD.name, NEW.name);
    END IF;
    
    -- Проверяем, изменилось ли поле email
    IF NEW.email IS DISTINCT FROM OLD.email THEN
        INSERT INTO users_audit (user_id, changed_by, field_changed, old_value, new_value)
        VALUES (NEW.id, current_user, 'email', OLD.email, NEW.email);
    END IF;
    
    -- Проверяем, изменилось ли поле role
    IF NEW.role IS DISTINCT FROM OLD.role THEN
        INSERT INTO users_audit (user_id, changed_by, field_changed, old_value, new_value)
        VALUES (NEW.id, current_user, 'role', OLD.role, NEW.role);
    END IF;
    NEW.updated_at = CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS users_update_trigger ON users;

CREATE TRIGGER users_update_trigger
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION log_user_changes();

--Функция экспорта аудита в CSV
CREATE OR REPLACE FUNCTION export_daily_user_changes()
RETURNS void AS $outer$
DECLARE
    export_date TEXT := TO_CHAR(CURRENT_DATE, 'YYYY_MM_DD');
    export_path TEXT := '/tmp/users_audit_export_' || export_date || '.csv';
BEGIN
    EXECUTE format(
        $inner$
        COPY (
            SELECT *
            FROM users_audit
            WHERE DATE(changed_at) >=  CURRENT_DATE - INTERVAL '2 day'
        ) TO %L WITH CSV HEADER
        $inner$, export_path
    );
END;
$outer$ LANGUAGE plpgsql;

SELECT cron.unschedule('daily_user_export');

SELECT cron.schedule(
    job_name := 'daily_user_export',
    schedule := '00 03 * * *',
    command := $$SELECT export_daily_user_changes();$$
);

SELECT * FROM cron.job;
