-- Table: public.stops

-- DROP TABLE IF EXISTS public.stops;

CREATE TABLE public.stops
(
    data_origin character varying(100) NOT NULL,
    id text NOT NULL,
    code text,
    name text,
    description text,
    latitude double precision NOT NULL,
    longitude double precision NOT NULL,
    geo_location geometry,
    zone text,
    url text,
    location_type integer,
    parent_station text,
    timezone text,
    wheelchair_boarding text,
    level_id text,
    platform_code text,
    stop_type integer,
    internal_id text NOT NULL,
    last_updated timestamp with time zone NOT NULL,
    import_id uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
    CONSTRAINT pk_stops PRIMARY KEY (internal_id),
    CONSTRAINT uq_stops_data_origin_id UNIQUE (data_origin, id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.stops
    OWNER to postgres;
-- Index: example1_gpx

CREATE INDEX idx_stops_internal_id_data_origin ON public.stops (internal_id, data_origin);
CREATE INDEX example1_gpx_new ON public.stops USING gist (geography(geo_location));
CREATE INDEX ix_stops_id ON public.stops USING btree (id);
CREATE INDEX ix_stops_id_data_origin ON public.stops USING btree (id, data_origin);
CREATE INDEX ix_stops_id_data_origin_stop_type ON public.stops USING btree (id, data_origin, stop_type);
CREATE INDEX ix_stops_id_parent_station ON public.stops USING btree (id, parent_station);
CREATE INDEX ix_stops_id_stop_type ON public.stops USING btree (id, stop_type);
CREATE INDEX ix_stops_import_id_data_origin ON public.stops USING btree (import_id, data_origin);
CREATE INDEX ix_stops_internal_id_stop_type ON public.stops USING btree (internal_id, stop_type);
CREATE INDEX ix_stops_name_stop_type ON public.stops USING btree (name, stop_type);
CREATE INDEX ix_stops_parent_station ON public.stops USING btree (parent_station);
CREATE INDEX ix_stops_stop_type ON public.stops USING btree (stop_type);
CREATE INDEX stops_hash_stop_type ON public.stops USING hash (stop_type);
CREATE INDEX ix_stops_name ON public.stops USING GIST (name gist_trgm_ops);