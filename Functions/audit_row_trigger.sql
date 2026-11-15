CREATE OR REPLACE FUNCTION public.audit_row_trigger()
    RETURNS trigger
    LANGUAGE plpgsql
AS $BODY$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO public.audit_log (table_name, operation, old_data, new_data, changed_by)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD), NULL,
                current_user || coalesce('|' || nullif(current_setting('application_name', true), ''), ''));
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO public.audit_log (table_name, operation, old_data, new_data, changed_by)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD), to_jsonb(NEW),
                current_user || coalesce('|' || nullif(current_setting('application_name', true), ''), ''));
        RETURN NEW;
    ELSE
        INSERT INTO public.audit_log (table_name, operation, old_data, new_data, changed_by)
        VALUES (TG_TABLE_NAME, TG_OP, NULL, to_jsonb(NEW),
                current_user || coalesce('|' || nullif(current_setting('application_name', true), ''), ''));
        RETURN NEW;
    END IF;
END;
$BODY$;
