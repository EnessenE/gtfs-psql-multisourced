-- Table: public.frequencies

-- DROP TABLE IF EXISTS public.frequencies;

CREATE TABLE IF NOT EXISTS public.frequencies
(
    data_origin character varying(100) NOT NULL,
    trip_id text NOT NULL,
    start_time text NOT NULL,
    end_time text NOT NULL,
    headway_secs text,
    exact_times boolean,
    internal_id uuid NOT NULL,
    last_updated timestamp with time zone NOT NULL,
    import_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
    CONSTRAINT pk_frequencies PRIMARY KEY (data_origin, trip_id, start_time, end_time)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.frequencies
    OWNER to postgres;
-- Index: ix_frequencies_import_id_data_origin

-- DROP INDEX IF EXISTS public.ix_frequencies_import_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_frequencies_import_id_data_origin
    ON public.frequencies USING btree
    (import_id ASC NULLS LAST, data_origin ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_frequencies_internal_id

-- DROP INDEX IF EXISTS public.ix_frequencies_internal_id;

CREATE INDEX IF NOT EXISTS ix_frequencies_internal_id
    ON public.frequencies USING btree
    (internal_id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_frequencies_trip_id_data_origin

-- DROP INDEX IF EXISTS public.ix_frequencies_trip_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_frequencies_trip_id_data_origin
    ON public.frequencies USING btree
    (trip_id ASC NULLS LAST, data_origin ASC NULLS LAST)
    TABLESPACE pg_default;