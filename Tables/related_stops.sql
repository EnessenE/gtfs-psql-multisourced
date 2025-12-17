
-- DROP TABLE IF EXISTS public.related_stops;

CREATE TABLE public.related_stops
(
    primary_stop uuid NOT NULL,
    related_stop BIGINT NOT NULL,
    related_data_origin text,
    CONSTRAINT related_stops_pkey PRIMARY KEY (primary_stop, related_stop)
    CONSTRAINT related_stops_unique UNIQUE (primary_stop, related_stop, related_data_origin);
    --CONSTRAINT fk_related_stops_related FOREIGN KEY (related_stop, related_data_origin) REFERENCES public.stops (internal_id, data_origin) ON DELETE CASCADE
);


CREATE INDEX related_stops_related_stop_primary_stop_idx ON public.related_stops USING btree (related_stop, primary_stop, related_data_origin);
CREATE INDEX related_stops_related_stop_idx ON public.related_stops USING btree (related_stop);
CREATE INDEX related_stops_primary_stop_idx ON public.related_stops USING btree (primary_stop);

