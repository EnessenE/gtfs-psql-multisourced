-- PROCEDURE: public.merge_stop(text, text)
-- DROP PROCEDURE IF EXISTS public.merge_stop(text, text);
CREATE OR REPLACE PROCEDURE public.upsert_alert_entities(target_data_origin text, target_internal_id uuid, target_last_updated timestamp with time zone, target_agency_id text, target_route_id text, target_trip_id text, target_stop_id text)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    INSERT INTO public.alert_entities(data_origin, internal_id, last_updated, agency_id, route_id, trip_id, stop_id)
        VALUES(target_data_origin, target_internal_id, target_last_updated, target_agency_id, target_route_id, target_trip_id, target_stop_id);
    -- ON CONFLICT(data_origin, agency_id, route_id, trip_id, stop_id)
    --     DO UPDATE SET
    --         last_updated = target_last_updated;
END;
$BODY$;

