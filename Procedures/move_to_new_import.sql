-- PROCEDURE: public.move_to_new_import(uuid, text)

-- DROP PROCEDURE IF EXISTS public.move_to_new_import(uuid, text);
CREATE OR REPLACE PROCEDURE public.move_to_new_import(
	IN target_id uuid,
	IN data_origin_target text)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    DELETE FROM calendar_dates
    WHERE import_id != target_id AND data_origin = data_origin_target;

    DELETE FROM calendars
    WHERE import_id != target_id AND data_origin = data_origin_target;

    DELETE FROM gtfs_services 
    WHERE import_id != target_id AND data_origin = data_origin_target;

    DELETE FROM pathway
    WHERE import_id != target_id AND data_origin = data_origin_target;

    DELETE FROM routes
    WHERE import_id != target_id AND data_origin = data_origin_target;

    DELETE FROM shapes
    WHERE import_id != target_id AND data_origin = data_origin_target;

    DELETE FROM stop_times
    WHERE import_id != target_id AND data_origin = data_origin_target;

    DELETE FROM stops
    WHERE import_id != target_id AND data_origin = data_origin_target;

    DELETE FROM transfers
    WHERE import_id != target_id AND data_origin = data_origin_target;

    DELETE FROM trips
    WHERE import_id != target_id AND data_origin = data_origin_target;
    
    DELETE FROM related_stops
    WHERE related_stop = ANY(ARRAY(
                SELECT
                    related_stop
                FROM
                    related_stops
                LEFT JOIN stops ON stops.internal_id = related_stops.related_stop
            WHERE
                stops.id IS NULL));
END
$BODY$;

ALTER PROCEDURE public.move_to_new_import(uuid, text)
    OWNER TO dennis;
