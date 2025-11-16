CREATE TABLE public.alert_active_periods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_internal_id UUID NOT NULL REFERENCES public.alerts(internal_id) ON DELETE CASCADE,
    start_time timestamp with time zone,
    end_time  timestamp with time zone,
    data_origin text not null,
    last_updated timestamp with time zone DEFAULT now()
);
