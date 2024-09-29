-- PROCEDURE: public.merge_stop(text, text)
-- DROP PROCEDURE IF EXISTS public.merge_stop(text, text);
CREATE OR REPLACE PROCEDURE public.cleanup_realtime_data()
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    DELETE FROM position_entities
    WHERE last_updated < now () - INTERVAL '1 hour';

    DELETE FROM alert_entities
    WHERE last_updated < now () - INTERVAL '1 hour';

    DELETE FROM alerts
    WHERE last_updated < now () - INTERVAL '1 hour';

    DELETE FROM trip_updates
    WHERE last_updated < now () - INTERVAL '1 hour';

    DELETE FROM trip_updates_stop_times
    WHERE last_updated < now () - INTERVAL '1 hour';
END;
$BODY$;

ALTER PROCEDURE public.cleanup_realtime_data() OWNER TO dennis;

