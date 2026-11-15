-- Table: public.audit_log
--
-- Schema-change audit log only: DDL (create/alter/drop of tables, routines, indexes,
-- ...) is written by the audit_ddl / audit_ddl_drop event triggers created by
-- apply_audit_triggers. Row-level DML is intentionally NOT audited.

CREATE TABLE public.audit_log
(
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    changed_at timestamp with time zone NOT NULL DEFAULT now(),
    -- for DDL audits: the object type (table, function, index, ...)
    table_name text NOT NULL,
    -- the DDL command tag (CREATE TABLE, ALTER FUNCTION, DROP INDEX, ...)
    operation text NOT NULL,
    -- the object identity (e.g. public.get_stop_from_id(text,integer))
    object_name text,
    old_data jsonb,
    new_data jsonb,
    changed_by text NOT NULL DEFAULT current_user,
    CONSTRAINT pk_audit_log PRIMARY KEY (id)
);

CREATE INDEX ix_audit_log_table_changed_at ON public.audit_log USING btree (table_name, changed_at DESC);
CREATE INDEX ix_audit_log_changed_at ON public.audit_log USING btree (changed_at DESC);
