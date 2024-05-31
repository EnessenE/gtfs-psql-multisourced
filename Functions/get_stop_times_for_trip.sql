-- FUNCTION: public.get_stop_times_for_trip(text)

DROP FUNCTION IF EXISTS public.get_stop_times_for_trip(text);

CREATE OR REPLACE FUNCTION public.get_stop_times_for_trip(
	target text)
    RETURNS TABLE(sequence bigint, id text, name text, arrival time without time zone, departure time without time zone, platformcode text, stopheadsign text, latitude double precision, longitude double precision) 
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
SELECT
    stop_times.stopsequence,
    stops.id,
    stops.name,
    stop_times.arrivaltime,
    stop_times.departuretime,
	stops.platformcode,
	stop_times.stopheadsign,
	stops.latitude, 
	stops.longitude
FROM
    stop_times
JOIN
    stops ON stop_times.stopid = stops.id
WHERE
    stop_times.tripid = target
ORDER BY
    stop_times.stopsequence;
$BODY$;

ALTER FUNCTION public.get_stop_times_for_trip(text)
    OWNER TO dennis;
