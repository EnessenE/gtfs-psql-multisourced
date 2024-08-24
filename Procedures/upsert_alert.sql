-- PROCEDURE: public.merge_stop(text, text)
-- DROP PROCEDURE IF EXISTS public.merge_stop(text, text);
CREATE OR REPLACE PROCEDURE public.upsert_alert(data_origin text, internal_id uuid, last_updated timestamp with time zone, active_periods uuid, cause text, effect text, url uuid, header_text uuid, description_text uuid, tts_header_text uuid, tts_description_text uuid, severity_level text)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    INSERT INTO public.alerts(data_origin, internal_id, last_updated, active_periods, cause, effect, url, header_text, description_text, tts_header_text, tts_description_text, severity_level)
        VALUES(data_origin, internal_id, last_updated, active_periods, cause, effect, url, header_text, description_text, tts_header_text, tts_description_text, severity_level);
END;
$BODY$;

