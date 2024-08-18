DROP FUNCTION public.get_stop_times_from_stop(uuid, int,  timestamp with time zone);

CREATE OR REPLACE FUNCTION public.get_stop_times_from_stop(target uuid, target_stop_type int, from_time timestamp with time zone)
    RETURNS TABLE(
        trip_id text,
        arrival_time timestamp with time zone ,
        departure_time timestamp with time zone,
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
SELECT
        trips.internal_id,
		 -- TO FIX FOR PICKUP/DROPOFF WINDOWS AND CALENDERS
        (coalesce(calendar_dates.date, (SELECT CURRENT_DATE)) + stop_times.arrival_time) AT time zone 'UTC'  as arrival_time,
        (coalesce(calendar_dates.date, (SELECT CURRENT_DATE)) + stop_times.departure_time) AT time zone 'UTC' as departure_time,
        stop_times.stop_headsign,
        stop_times.data_origin,
        trips.headsign,
        trips.short_name,
        stops.platform_code,
        trips.service_id,
        routes.short_name,
        routes.long_name,
        agencies.name,
        routes.url,
        routes.type,
        routes.description,
        routes.color,
        routes.text_color,
        stops.stop_type
    FROM
        trips
    INNER JOIN routes ON trips.route_id = routes.id
            AND trips.data_origin = routes.data_origin
	INNER JOIN stop_times ON stop_times.trip_id = trips.id
		AND stop_times.data_origin = trips.data_origin
	INNER JOIN stops ON stop_times.stop_id = stops.id AND stop_times.data_origin = stops.data_origin 
	INNER JOIN related_stops ON related_stops.related_stop = stops.internal_id
	INNER JOIN agencies ON routes.agency_id = agencies.id AND routes.data_origin = agencies.data_origin
	LEFT JOIN calendar_dates ON trips.service_id = calendar_dates.service_id AND calendar_dates.data_origin = trips.data_origin 
	LEFT JOIN calenders ON trips.service_id = calenders.service_id AND calenders.data_origin = trips.data_origin 
   WHERE
        --parent_station / station filter
		(primary_stop = target)
			AND stop_type = target_stop_type
            --Date filter
                    
            AND(    ((calendar_dates.date:: date + stop_times.arrival_time::time without time zone) >= from_time) OR ( calenders.start_date >= from_time AND (
                (EXTRACT(DOW FROM from_time) = 0 AND sunday = true) OR
                (EXTRACT(DOW FROM from_time) = 1 AND monday = true) OR
                (EXTRACT(DOW FROM from_time) = 2 AND tuesday = true) OR
                (EXTRACT(DOW FROM from_time) = 3 AND wednesday = true) OR
                (EXTRACT(DOW FROM from_time) = 4 AND thursday = true) OR
                (EXTRACT(DOW FROM from_time) = 5 AND friday = true) OR
                (EXTRACT(DOW FROM from_time) = 6 AND saturday = true))))

            -- Prevent showing the trip if the current stop is the last stop
            AND EXISTS(
                SELECT
                    1
                FROM
                    stop_times st2
                WHERE
					st2.data_origin = stop_times.data_origin
                    AND st2.trip_id = stop_times.trip_id
                    AND st2.stop_sequence > stop_times.stop_sequence
	LIMIT 1)
        ORDER BY
            coalesce(calendar_dates.date, (SELECT CURRENT_DATE)) + stop_times.arrival_time ASC,
            arrival_time ASC
        LIMIT 100;

$BODY$;

ALTER FUNCTION public.get_stop_times_from_stop(uuid, int, timestamp with time zone ) OWNER TO dennis;

SELECT * FROM get_stop_times_from_stop('3c849953-509b-4d2a-b9b4-f3ec1975eb57'::uuid, 100, '2024-08-18 14:27Z');
