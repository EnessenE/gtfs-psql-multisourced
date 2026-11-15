-- Event trigger function: logs every create/alter/drop of a function or procedure
-- (the "sproc" part of the audit) into audit_log. Created by apply_audit_triggers.

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
        WHERE object_type IN ('function', 'procedure')
    LOOP
        INSERT INTO public.audit_log (table_name, operation, object_name, old_data, new_data, changed_by)
        VALUES ('pg_proc', cmd.command_tag, cmd.object_identity, NULL,
                jsonb_build_object(
                    'command_tag', cmd.command_tag,
                    'object_type', cmd.object_type,
                    'object_identity', cmd.object_identity),
                current_user || coalesce('|' || nullif(current_setting('application_name', true), ''), ''));
    END LOOP;
END;
$BODY$;

-- sql_drop event: logs dropped functions/procedures (drops do not appear in
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
        WHERE object_type IN ('function', 'procedure')
    LOOP
        INSERT INTO public.audit_log (table_name, operation, object_name, old_data, new_data, changed_by)
        VALUES ('pg_proc', 'DROP ' || upper(cmd.object_type), cmd.object_identity, NULL,
                jsonb_build_object('object_type', cmd.object_type, 'object_identity', cmd.object_identity),
                current_user || coalesce('|' || nullif(current_setting('application_name', true), ''), ''));
    END LOOP;
END;
$BODY$;
