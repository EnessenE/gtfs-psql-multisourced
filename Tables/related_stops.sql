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


CREATE INDEX example1_gpx ON stops USING GIST (geography(geo_location));
