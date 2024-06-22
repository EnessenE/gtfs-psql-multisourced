-- Table: public.related_stops

-- DROP TABLE IF EXISTS public.related_stops;

CREATE TABLE IF NOT EXISTS public.related_stops
(
    primary_stop text COLLATE pg_catalog."default" NOT NULL,
    related_stop text COLLATE pg_catalog."default" NOT NULL,
    related_data_origin text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT related_stops_pkey PRIMARY KEY (primary_stop, related_stop, related_data_origin)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.related_stops
    OWNER to dennis;

CREATE INDEX IF NOT EXISTS ix_related_stops_related_stop_related_data_origin
    ON public.related_stops USING btree
    (related_stop COLLATE pg_catalog."default" ASC NULLS LAST, related_data_origin COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_pathway_data_origin

-- DROP INDEX IF EXISTS public.ix_pathway_data_origin;

CREATE INDEX IF NOT EXISTS ix_related_stops_related_stop_primary_stop_related_data_origin
    ON public.related_stops USING btree
    (related_stop COLLATE pg_catalog."default" ASC NULLS LAST, primary_stop COLLATE pg_catalog."default" ASC NULLS LAST, related_data_origin COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_pathway_data_origin

-- DROP INDEX IF EXISTS public.ix_pathway_data_origin;

CREATE INDEX IF NOT EXISTS ix_related_stops_related_stop_primary_stop
    ON public.related_stops USING btree
    (related_stop COLLATE pg_catalog."default" ASC NULLS LAST, primary_stop COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_pathway_data_origin

-- DROP INDEX IF EXISTS public.ix_pathway_data_origin;

CREATE INDEX IF NOT EXISTS ix_related_stops_related_stop
    ON public.related_stops USING btree
    (related_stop COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: ix_pathway_data_origin

-- DROP INDEX IF EXISTS public.ix_pathway_data_origin;

CREATE INDEX IF NOT EXISTS ix_related_stops_primary_stop
    ON public.related_stops USING btree
    (primary_stop COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;

CREATE INDEX example1_gpx ON stops USING GIST (geography(geo_location));
