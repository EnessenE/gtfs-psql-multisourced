CREATE TABLE public.gtfs_services (
    service_handle_id serial PRIMARY KEY,
    import_id uuid NOT NULL,
    data_origin text NOT NULL,
    service_id text NOT NULL,
    UNIQUE (import_id, service_id)
);


ALTER TABLE public.trips ADD COLUMN service_handle_id integer REFERENCES public.gtfs_services(service_handle_id);
CREATE INDEX idx_trips_service_handle ON public.trips (service_handle_id);