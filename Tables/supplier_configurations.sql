-- In reality we should split off this table to a "imports" table for historic data. But for now its a fine hack
CREATE TABLE IF NOT EXISTS public.supplier_configurations
(
    name text NOT NULL,
    retrieval_type integer NOT NULL,
    data_type integer NOT NULL,
    polling_rate interval NOT NULL,
    url text NOT NULL,
    last_updated timestamp with time zone NOT NULL DEFAULT '1970-01-01 00:00:00+01'::timestamp with time zone,
    download_pending boolean NOT NULL DEFAULT false,
    import_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
    latest_succesfull_import_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
    last_attempt timestamp with time zone,
    e_tag text,
    last_checked timestamp with time zone,
    last_check_failure timestamp with time zone,
    state text NOT NULL DEFAULT 'unknown'::text,
    last_check timestamp with time zone NOT NULL,
    last_import_start timestamp with time zone NULL,
    last_import_success timestamp with time zone NULL,
    last_import_failure timestamp with time zone NULL,
    last_duration time without time zone NOT NULL DEFAULT '00:00:00'::time without time zone,
    queued_import_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
    header text NULL,
    header_secret text NULL,
    CONSTRAINT pk_supplier_configurations PRIMARY KEY (name)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.supplier_configurations
    OWNER to postgres;