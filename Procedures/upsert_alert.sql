-- PROCEDURE: public.merge_stop(text, text)
-- DROP PROCEDURE IF EXISTS public.merge_stop(text, text);
CREATE OR REPLACE PROCEDURE public.upsert_alert(target_data_origin text, target_internal_id uuid, target_id text, target_last_updated timestamp with time zone, target_active_periods uuid, target_cause text, target_effect text, target_url text, target_header_text text, target_description_text text, target_tts_header_text text, target_tts_description_text text, target_severity_level text)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    INSERT INTO public.alerts(data_origin, internal_id, id, last_updated, active_periods, cause, effect, url, header_text, description_text, tts_header_text, tts_description_text, severity_level)
        VALUES(target_data_origin, target_internal_id, target_id, target_last_updated, target_active_periods, target_cause, target_effect, target_url, target_header_text, target_description_text, target_tts_header_text, target_tts_description_text, target_severity_level)
    ON CONFLICT(data_origin, id)
        DO UPDATE SET
            last_updated = target_last_updated, active_periods = target_active_periods, cause = target_cause, effect = target_effect, url = target_url, header_text = target_header_text, description_text = target_description_text, tts_header_text = target_tts_header_text, tts_description_text = target_tts_description_text, severity_level = target_severity_level;
END;
$BODY$;

