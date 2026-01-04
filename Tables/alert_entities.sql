CREATE TABLE public.alert_entities (
    internal_id bigint GENERATED ALWAYS AS IDENTITY,
    data_origin varchar(100) NOT NULL,
    alert_id text NOT NULL,
    created timestamptz NOT NULL DEFAULT timezone('utc', now()),
    last_updated timestamptz NOT NULL,

    agency_id text,
    route_id text,
    trip_id text,
    stop_id text,

    CONSTRAINT pk_alert_entities PRIMARY KEY (internal_id),
    
    CONSTRAINT uq_alert_entities_logical UNIQUE NULLS NOT DISTINCT (
        data_origin, 
        alert_id, 
        agency_id, 
        route_id, 
        trip_id, 
        stop_id
    ),

    CONSTRAINT fk_alert_entities_alert
        FOREIGN KEY (data_origin, alert_id)
        REFERENCES public.alerts (data_origin, id)
        ON DELETE CASCADE
);