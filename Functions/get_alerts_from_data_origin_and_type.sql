DROP FUNCTION IF EXISTS public.get_alerts_from_data_origin_and_type(text, integer);

CREATE OR REPLACE FUNCTION public.get_alerts_from_data_origin_and_type(target_data_origin text, target_stop_type integer)
    RETURNS TABLE(
        stop_id text,
        stop_data_origin text,
        primary_stop uuid,
        alert_id text,
        alert_data_origin text,
        created timestamp with time zone,
        last_updated timestamp with time zone,
        is_deleted boolean,
        active_periods uuid,
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
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
        SELECT DISTINCT
            stops.id,
            stops.data_origin,
            related_stops.primary_stop,
            alerts.id,
            alerts.data_origin,
            alerts.created,
            alerts.last_updated,
            alerts.is_deleted,
            alerts.active_periods,
            COALESCE(alerts.cause, 'UNKNOWN'),
            COALESCE(alerts.effect, 'UNKNOWN'),
            alerts.url,
            alerts.header_text,
            alerts.description_text,
            alerts.tts_header_text,
            alerts.tts_description_text,
            COALESCE(alerts.severity_level, 'UNKNOWN')
        FROM public.alerts
        INNER JOIN public.alert_entities ON alerts.id = alert_entities.alert_id AND public.alerts.data_origin = public.alert_entities.data_origin
        INNER JOIN public.stops ON public.alert_entities.stop_id = public.stops.id AND public.alert_entities.data_origin = public.stops.data_origin
	    INNER JOIN related_stops ON related_stops.related_stop = stops.internal_id
        WHERE
            public.stops.stop_type = target_stop_type 
            AND public.alerts.is_deleted = false
            AND public.alerts.data_origin = target_data_origin
        ORDER BY 
            alerts.last_updated DESC
        LIMIT 100;
$BODY$;