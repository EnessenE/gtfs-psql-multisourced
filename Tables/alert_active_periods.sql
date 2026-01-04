CREATE TABLE public.alert_active_periods (
    id text NOT NULL,
    data_origin text NOT NULL,
    start_time timestamptz,
    end_time timestamptz,
    last_updated timestamptz DEFAULT now(),

    PRIMARY KEY (id, data_origin),

    CONSTRAINT alert_active_periods_alert_fk
        FOREIGN KEY (id, data_origin)
        REFERENCES public.alerts (id, data_origin)
        ON DELETE CASCADE
);
