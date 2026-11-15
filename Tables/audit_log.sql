-- Table: public.audit_log
--
-- Generic audit log. Row changes are written by audit_row_trigger (attached to every
-- core table by apply_audit_triggers); function/procedure DDL is written by the
-- audit_ddl event trigger (also created by apply_audit_triggers).

CREATE TABLE public.audit_log
(
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    changed_at timestamp with time zone NOT NULL DEFAULT now(),
    -- table for row audits, 'pg_proc' for routine (function/procedure) DDL audits
    table_name text NOT NULL,
    -- INSERT / UPDATE / DELETE, or the DDL command tag (CREATE FUNCTION, DROP PROCEDURE, ...)
    operation text NOT NULL,
    -- for DDL audits: the object identity (e.g. public.get_stop_from_id(text,integer))
    object_name text,
    old_data jsonb,
    new_data jsonb,
    changed_by text NOT NULL DEFAULT current_user,
    CONSTRAINT pk_audit_log PRIMARY KEY (id)
);

CREATE INDEX ix_audit_log_table_changed_at ON public.audit_log USING btree (table_name, changed_at DESC);
CREATE INDEX ix_audit_log_changed_at ON public.audit_log USING btree (changed_at DESC);
