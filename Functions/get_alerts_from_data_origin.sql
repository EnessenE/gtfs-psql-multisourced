DROP FUNCTION IF EXISTS public.get_alerts_from_data_origin(TEXT);

CREATE OR REPLACE FUNCTION public.get_alerts_from_data_origin(
    p_data_origin TEXT
)
RETURNS TABLE (
    data_origin text,
    internal_id text,
    created timestamp with time zone,
    last_updated timestamp with time zone,
    id text,
    is_deleted boolean,
    active_periods text,
    cause text,
    effect text,
    url text,
    header_text text,
    description_text text,
    tts_header_text text,
    tts_description_text text,
    severity_level text
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        alerts.data_origin,
        alerts.internal_id ::text,
        alerts.created,
        alerts.last_updated,
        alerts.id,
        alerts.is_deleted,
        alerts.active_periods::text,
        alerts.cause,
        alerts.effect,
        alerts.url,
        alerts.header_text,
        alerts.description_text,
        alerts.tts_header_text,
        alerts.tts_description_text,
        alerts.severity_level
    FROM
        public.alerts
    WHERE
        alerts.data_origin = p_data_origin;
END;
$$;

select * from get_alerts_from_data_origin('OpenOV')