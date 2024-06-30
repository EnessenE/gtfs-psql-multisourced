DROP FUNCTION public.get_stop_times_from_stop(uuid, int, time without time zone, date);

CREATE OR REPLACE FUNCTION public.get_stop_times_from_stop(target uuid, target_stop_type int, from_time time without time zone, from_date date)
    RETURNS TABLE(
        trip_id text,
        arrival_time time without time zone,
        departure_time time without time zone,
        stop_headsign text,
        data_origin text,
        headsign text,
        short_name text,
        platform text,
        service_id text,
        route_short_name text,
        route_long_name text,
        OPERATOR text,
        route_url text,
        route_type text,
        route_desc text,
        route_color text,
        route_text_color text,
        stop_type bigint)
    LANGUAGE 'sql'
    COST 500 VOLATILE PARALLEL UNSAFE ROWS 100
    AS $BODY$
WITH filtered_stop_times AS (
    SELECT 
        stop_times.trip_id,
        stop_times.arrival_time,
        stop_times.departure_time,
        stop_times.stop_headsign,
        stop_times.data_origin,
        stop_times.stop_id,
        stop_times.stop_sequence
    FROM stop_times
    WHERE stop_times.stop_id IN (
        SELECT stops.id
        FROM stops
        INNER JOIN related_stops ON related_stops.related_stop = stops.internal_id AND related_stops.related_data_origin = stops.data_origin
        WHERE related_stops.primary_stop = target
          AND stops.stop_type = target_stop_type
    )
    AND stop_times.arrival_time >= from_time::time
),
valid_trips AS (
    SELECT 
        trips.id AS trip_id,
        trips.internal_id,
        trips.headsign,
        trips.short_name AS trip_short_name,
        trips.service_id,
        trips.data_origin,
        routes.short_name AS route_short_name,
        routes.long_name,
        routes.url,
        routes.type,
        routes.description,
        routes.color,
        routes.text_color,
        agencies.name AS agency_name
    FROM trips
    INNER JOIN routes ON trips.route_id = routes.id
        AND trips.data_origin = routes.data_origin
    INNER JOIN agencies ON routes.agency_id = agencies.id
        AND routes.data_origin = agencies.data_origin
	WHERE trips.id = ANY(SELECT filtered_stop_times.trip_id FROM filtered_stop_times)
),

service_dates AS (
    SELECT DISTINCT service_id, data_origin, date
    FROM calendar_dates
    WHERE date >= from_date::date
)

-- Main query
SELECT
    valid_trips.internal_id,
    fst.arrival_time,
    fst.departure_time,
    fst.stop_headsign,
    fst.data_origin,
    valid_trips.headsign,
    valid_trips.trip_short_name,
    stops.platform_code,
    valid_trips.service_id,
    valid_trips.route_short_name,
    valid_trips.long_name,
    valid_trips.agency_name,
    valid_trips.url,
    valid_trips.type,
    valid_trips.description,
    valid_trips.color,
    valid_trips.text_color,
    stops.stop_type
FROM
    filtered_stop_times fst
INNER JOIN valid_trips ON fst.trip_id = valid_trips.trip_id
INNER JOIN stops ON fst.stop_id = stops.id 
    AND fst.data_origin = stops.data_origin
INNER JOIN service_dates ON valid_trips.service_id = service_dates.service_id
    AND valid_trips.data_origin = service_dates.data_origin
WHERE
    ((fst.arrival_time >= from_time::time AND service_dates.date::date >= from_date::date)
    OR (service_dates.date::date > from_date::date))
    AND EXISTS (
        SELECT 1
        FROM stop_times st2 
        WHERE st2.trip_id = fst.trip_id
          AND st2.stop_sequence > fst.stop_sequence
    )
	
ORDER BY
    service_dates.date::date,
    fst.arrival_time ASC
LIMIT 100;

$BODY$;

ALTER FUNCTION public.get_stop_times_from_stop(uuid, int, time WITHOUT time zone, date) OWNER TO dennis;

SELECT * FROM get_stop_times_from_stop('4a340208-d3fd-4029-a35d-29675bb0ea76'::uuid, 1, '17:40'::time without time zone, '2024-06-22'::date);

