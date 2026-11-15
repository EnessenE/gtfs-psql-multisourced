-- audit_log is schema-only: this procedure removes any row-level DML audit triggers
-- (and their function) and (re)creates the DDL event triggers that log schema changes
-- into audit_log. Idempotent.

CREATE OR REPLACE PROCEDURE public.apply_audit_triggers()
    LANGUAGE plpgsql
AS $BODY$
DECLARE
    r record;
BEGIN
    -- Remove row-level DML auditing everywhere
    FOR r IN
        SELECT c.relname AS tablename
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        JOIN pg_trigger t ON t.tgrelid = c.oid
        WHERE n.nspname = 'public'
          AND t.tgname = 'audit_row_trigger'
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS audit_row_trigger ON public.%I', r.tablename);
        RAISE NOTICE 'dropped audit_row_trigger from %.%', 'public', r.tablename;
    END LOOP;
    DROP FUNCTION IF EXISTS public.audit_row_trigger();

    -- Schema-change auditing
    DROP EVENT TRIGGER IF EXISTS audit_ddl;
    CREATE EVENT TRIGGER audit_ddl
        ON ddl_command_end
        EXECUTE FUNCTION public.audit_ddl_trigger();
    DROP EVENT TRIGGER IF EXISTS audit_ddl_drop;
    CREATE EVENT TRIGGER audit_ddl_drop
        ON sql_drop
        EXECUTE FUNCTION public.audit_sql_drop_trigger();
    RAISE NOTICE 'audit_ddl event triggers created';
END;
$BODY$;
