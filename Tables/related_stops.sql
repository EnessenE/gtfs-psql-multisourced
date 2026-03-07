-- Table: public.related_stops

-- DROP TABLE IF EXISTS public.related_stops;

CREATE TABLE IF NOT EXISTS public.related_stops
(
    primary_stop uuid NOT NULL,
    related_stop bigint NOT NULL,
    related_data_origin text COLLATE pg_catalog."default",
    CONSTRAINT related_stops_pkey PRIMARY KEY (primary_stop, related_stop),
    CONSTRAINT related_stops_unique UNIQUE (primary_stop, related_stop, related_data_origin)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.related_stops
    OWNER to postgres;
-- Index: related_stops_primary_stop_idx

-- DROP INDEX IF EXISTS public.related_stops_primary_stop_idx;

CREATE INDEX IF NOT EXISTS related_stops_primary_stop_idx
    ON public.related_stops USING btree
    (primary_stop ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;
-- Index: related_stops_related_stop_idx

-- DROP INDEX IF EXISTS public.related_stops_related_stop_idx;

CREATE INDEX IF NOT EXISTS related_stops_related_stop_idx
    ON public.related_stops USING btree
    (related_stop ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;
-- Index: related_stops_related_stop_primary_stop_idx

-- DROP INDEX IF EXISTS public.related_stops_related_stop_primary_stop_idx;

CREATE INDEX IF NOT EXISTS related_stops_related_stop_primary_stop_idx
    ON public.related_stops USING btree
    (related_stop ASC NULLS LAST, primary_stop ASC NULLS LAST, related_data_origin COLLATE pg_catalog."default" ASC NULLS LAST)
    WITH (fillfactor=100, deduplicate_items=True)
    TABLESPACE pg_default;