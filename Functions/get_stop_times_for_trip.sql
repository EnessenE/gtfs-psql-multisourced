CREATE OR REPLACE FUNCTION public.get_stop_times_for_trip(target text)
    RETURNS TABLE(sequence bigint, id text, name text, arrivaltime time without time zone, departure time without time zone, platformcode text, stopheadsign text) 
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
	stop_times.stopheadsign
FROM
    stop_times
JOIN
    stops ON stop_times.stopid = stops.id
WHERE
    stop_times.tripid = target
ORDER BY
    stop_times.stopsequence;
$BODY$;

SELECT * FROM public.get_stop_times_for_trip('88____:A71::8821006:8822715:10:723:20240907')