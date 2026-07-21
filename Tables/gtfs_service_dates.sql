CREATE TABLE public.gtfs_service_dates (
    service_handle_id integer NOT NULL REFERENCES public.gtfs_services(service_handle_id) ON DELETE CASCADE,
    service_date date NOT NULL,
    PRIMARY KEY (service_handle_id, service_date)
);

CREATE INDEX idx_gsd_date_handle ON public.gtfs_service_dates (service_date, service_handle_id);