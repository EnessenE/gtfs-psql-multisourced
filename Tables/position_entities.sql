-- Table: public.position_entities

-- DROP TABLE IF EXISTS public.position_entities;

CREATE TABLE IF NOT EXISTS public.position_entities
(
    data_origin character varying(100) COLLATE pg_catalog."default" NOT NULL,
    internal_id uuid NOT NULL,
    last_updated timestamp with time zone NOT NULL,

    id text COLLATE pg_catalog."default" NOT NULL,
    trip_id text COLLATE pg_catalog."default",

    latitude double precision,
    longitude double precision,
    geo_location geometry,

    stop_id text,
    current_status text,
    measurement_time timestamp with time zone NULL,

    congestion_level text,

    occupancy_status text,
    occupancy_percentage integer,

    CONSTRAINT pk_position_entities PRIMARY KEY (data_origin, id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.position_entities
    OWNER to postgres;
-- Index: example1_gpx

-- DROP INDEX IF EXISTS public.example1_gpx;

CREATE INDEX IF NOT EXISTS ix_position_entities_geo_location
    ON public.position_entities USING gist
    (geography(geo_location))
    TABLESPACE pg_default;
-- Index: ix_position_entities_id

-- DROP INDEX IF EXISTS public.ix_position_entities_id;

CREATE INDEX IF NOT EXISTS ix_position_entities_id
    ON public.position_entities USING btree
    (id COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_position_entities_id_data_origin

-- DROP INDEX IF EXISTS public.ix_position_entities_id_data_origin;

CREATE INDEX IF NOT EXISTS ix_position_entities_id_data_origin
    ON public.position_entities USING btree
    (id COLLATE pg_catalog."default" ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS ix_position_entities_trip_id_data_origin

-- Index: ix_position_entities_id_data_origin_stop_typeCREATE INDEX IF NOT EXISTS ix_position_entities_id_data_origin
    ON public.position_entities USING btree
    (trip_id COLLATE pg_catalog."default" ASC NULLS LAST, data_origin COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_position_entities_id_data_origin_stop_type