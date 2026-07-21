-- PROCEDURE: public.delete_old_data_origin(text)

-- DROP PROCEDURE IF EXISTS public.delete_old_data_origin(text);
CREATE OR REPLACE PROCEDURE public.delete_old_data_origin(
	IN data_origin_target text)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
	IF data_origin_target IS NULL OR btrim(data_origin_target) = '' THEN
		RAISE EXCEPTION 'data_origin_target cannot be null or empty';
	END IF;

	DELETE FROM related_stops
	WHERE related_data_origin = data_origin_target;

	DELETE FROM stop_times
	WHERE data_origin = data_origin_target;

	DELETE FROM frequencies
	WHERE data_origin = data_origin_target;

	DELETE FROM trips
	WHERE data_origin = data_origin_target;

	DELETE FROM calendar_dates
	WHERE data_origin = data_origin_target;

	DELETE FROM calendars
	WHERE data_origin = data_origin_target;

	DELETE FROM shapes
	WHERE data_origin = data_origin_target;

	DELETE FROM routes
	WHERE data_origin = data_origin_target;

	DELETE FROM stops
	WHERE data_origin = data_origin_target;

	DELETE FROM agencies
	WHERE data_origin = data_origin_target;

	DELETE FROM gtfs_services
	WHERE data_origin = data_origin_target;
END;
$BODY$;
ALTER PROCEDURE public.delete_old_data_origin(text)
	OWNER TO dennis;
