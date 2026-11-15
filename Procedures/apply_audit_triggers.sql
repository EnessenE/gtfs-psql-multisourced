-- Attaches the audit row trigger to every core table (skipping the audit log itself,
-- per-import staging tables and partitions, which inherit the parent's trigger) and
-- creates the DDL event trigger for function/procedure changes. Idempotent.

CREATE OR REPLACE PROCEDURE public.apply_audit_triggers()
    LANGUAGE plpgsql
AS $BODY$
DECLARE
    r record;
BEGIN
    FOR r IN
        SELECT c.relname AS tablename
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public'
          AND c.relkind IN ('r', 'p')          -- plain and partitioned tables
          AND c.relname <> 'audit_log'
          AND c.relname <> 'spatial_ref_sys'
          AND c.relname !~ '^[A-Za-z]+_[0-9a-f]{8}_'  -- per-import staging tables (e.g. OpenOV_661c5bae_...)
          AND NOT EXISTS (SELECT 1 FROM pg_inherits i WHERE i.inhrelid = c.oid)  -- partitions inherit the parent trigger
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS audit_row_trigger ON public.%I', r.tablename);
        EXECUTE format(
            'CREATE TRIGGER audit_row_trigger AFTER INSERT OR UPDATE OR DELETE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.audit_row_trigger()',
            r.tablename);
        RAISE NOTICE 'audit trigger attached to %.%', 'public', r.tablename;
    END LOOP;

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
