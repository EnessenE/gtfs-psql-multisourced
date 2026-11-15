-- Event trigger function: logs every schema change (create/alter/drop of tables,
-- indexes, functions, procedures, types, ...) into audit_log. Created by
-- apply_audit_triggers. audit_log is schema-only: row-level DML is NOT audited.

CREATE OR REPLACE FUNCTION public.audit_ddl_trigger()
    RETURNS event_trigger
    LANGUAGE plpgsql
AS $BODY$
DECLARE
    cmd record;
BEGIN
    FOR cmd IN
        SELECT command_tag, object_type, object_identity
        FROM pg_event_trigger_ddl_commands()
    LOOP
        INSERT INTO public.audit_log (table_name, operation, object_name, new_data, changed_by)
        VALUES (coalesce(cmd.object_type, 'schema'), cmd.command_tag, cmd.object_identity,
                jsonb_build_object(
                    'command_tag', cmd.command_tag,
                    'object_type', cmd.object_type,
                    'object_identity', cmd.object_identity),
                current_user || coalesce('|' || nullif(current_setting('application_name', true), ''), ''));
    END LOOP;
END;
$BODY$;

-- sql_drop event: logs dropped objects (drops do not appear in
-- pg_event_trigger_ddl_commands, only in pg_event_trigger_dropped_objects).
CREATE OR REPLACE FUNCTION public.audit_sql_drop_trigger()
    RETURNS event_trigger
    LANGUAGE plpgsql
AS $BODY$
DECLARE
    cmd record;
BEGIN
    FOR cmd IN
        SELECT object_type, object_identity
        FROM pg_event_trigger_dropped_objects()
    LOOP
        INSERT INTO public.audit_log (table_name, operation, object_name, new_data, changed_by)
        VALUES (coalesce(cmd.object_type, 'schema'), 'DROP ' || upper(coalesce(cmd.object_type, 'object')), cmd.object_identity,
                jsonb_build_object('object_type', cmd.object_type, 'object_identity', cmd.object_identity),
                current_user || coalesce('|' || nullif(current_setting('application_name', true), ''), ''));
    END LOOP;
END;
$BODY$;
