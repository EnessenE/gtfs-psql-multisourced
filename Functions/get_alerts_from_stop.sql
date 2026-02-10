DROP FUNCTION IF EXISTS public.get_alerts_from_stop(uuid, integer);

CREATE OR REPLACE FUNCTION public.get_alerts_from_stop(
    target_stop_id uuid,
    target_stop_type integer
)
RETURNS TABLE (
    data_origin text,
    created timestamp with time zone,
    last_updated timestamp with time zone,
    id text,
    is_deleted boolean,
    cause text,
    effect text,
    url text,
    header_text text,
    description_text text,
    tts_header_text text,
    tts_description_text text,
    severity_level text,
    start_time timestamptz,
    end_time timestamptz
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT ON (alerts.id, alerts.data_origin)
        alerts.data_origin,
        alerts.created,
        alerts.last_updated,
        alerts.id,
        alerts.is_deleted,
        alerts.cause,
        alerts.effect,
        alerts.url,
        alerts.header_text,
        alerts.description_text,
        alerts.tts_header_text,
        alerts.tts_description_text,
        alerts.severity_level,
        alert_active_periods.start_time,
        alert_active_periods.end_time
    FROM
        public.related_stops
    INNER JOIN public.stops ON stops.internal_id = related_stops.related_stop
    INNER JOIN public.alert_entities ON stops.id = alert_entities.stop_id and stops.data_origin = alert_entities.data_origin
    INNER JOIN public.alerts ON alert_entities.alert_id = alerts.id AND alert_entities.data_origin = alerts.data_origin
    INNER JOIN public.alert_active_periods ON alert_active_periods.id = alerts.id AND alert_active_periods.data_origin = alerts.data_origin
	WHERE
        related_stops.primary_stop = target_stop_id
    AND
        stops.stop_type = target_stop_type
    AND now() BETWEEN alert_active_periods.start_time AND alert_active_periods.end_time
    ORDER BY 
        alerts.id, alerts.data_origin, alerts.last_updated DESC;
END;
$$;

select * from get_alerts_from_stop('3ea52064-ef36-40af-bf7a-2a2d38175851', 700)
