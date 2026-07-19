CREATE OR REPLACE FUNCTION public.get_alerts_from_data_origin(
	p_data_origin text,
	p_limit integer DEFAULT 100,
	p_offset integer DEFAULT 0)
    RETURNS TABLE(
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
        severity_level text
    ) 
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000
AS $BODY$
    SELECT
        alerts.data_origin,
        alerts.created,
        alerts.last_updated,
        alerts.id,
        alerts.is_deleted,
        COALESCE(alerts.cause, 'UNKNOWN'),
        COALESCE(alerts.effect, 'UNKNOWN'),
        alerts.url,
        alerts.header_text,
        alerts.description_text,
        alerts.tts_header_text,
        alerts.tts_description_text,
        COALESCE(alerts.severity_level, 'UNKNOWN')
    FROM
        public.alerts
    WHERE
        alerts.data_origin = p_data_origin
        AND alerts.is_deleted = false
    ORDER BY
        alerts.last_updated DESC
    -- LEAST ensures that if a user passes 500, it stays at 100. 
    -- It also handles negative numbers if you want to be even safer.
    LIMIT LEAST(p_limit, 100) OFFSET p_offset
$BODY$;

ALTER FUNCTION public.get_alerts_from_data_origin(text, integer, integer)
    OWNER TO postgres;