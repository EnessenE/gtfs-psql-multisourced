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
        severity_level text,
        start_time timestamp with time zone,
        end_time timestamp with time zone
    ) 
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000
AS $BODY$
    SELECT
        a.data_origin,
        a.created,
        a.last_updated,
        a.id,
        a.is_deleted,
        COALESCE(a.cause, 'UNKNOWN'),
        COALESCE(a.effect, 'UNKNOWN'),
        a.url,
        a.header_text,
        a.description_text,
        a.tts_header_text,
        a.tts_description_text,
        COALESCE(a.severity_level, 'UNKNOWN') AS severity_level,
        MIN(ap.start_time) AS start_time,
        MAX(ap.end_time) AS end_time
    FROM
        public.alerts a
    LEFT JOIN public.alert_active_periods ap
        ON ap.id = a.id
       AND ap.data_origin = a.data_origin
    WHERE
        a.data_origin = p_data_origin
        AND a.is_deleted = false
    GROUP BY
        a.data_origin,
        a.created,
        a.last_updated,
        a.id,
        a.is_deleted,
        a.cause,
        a.effect,
        a.url,
        a.header_text,
        a.description_text,
        a.tts_header_text,
        a.tts_description_text,
        a.severity_level
    ORDER BY
        a.last_updated DESC
    -- LEAST ensures that if a user passes 500, it stays at 100. 
    -- It also handles negative numbers if you want to be even safer.
    LIMIT LEAST(p_limit, 100) OFFSET p_offset
$BODY$;

ALTER FUNCTION public.get_alerts_from_data_origin(text, integer, integer)
    OWNER TO postgres;