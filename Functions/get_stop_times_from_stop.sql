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
        (calendar_dates.date + stop_times.arrival_time)  AT time zone agencies.timezone as arrival_time,
        (calendar_dates.date + stop_times.departure_time)  AT time zone agencies.timezone as departure_time,
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
	INNER JOIN agencies ON routes.agency_id = agencies.id
		AND routes.data_origin = agencies.data_origin
	INNER JOIN calendar_dates ON trips.service_id = calendar_dates.service_id
    WHERE
        -- parent_station / station filter
(primary_stop = target)
	AND stop_type = target_stop_type

            -- Date filter
                    
            AND((calendar_dates.date:: date + stop_times.arrival_time::time without time zone) AT time zone agencies.timezone  >= from_time AT time zone agencies.timezone)

            --Prevent showing the trip if the current stop is the last stop
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
            calendar_dates.date::date,
            arrival_time ASC
        LIMIT 100;

$BODY$;

ALTER FUNCTION public.get_stop_times_from_stop(uuid, int, timestamp with time zone ) OWNER TO dennis;

SELECT * FROM get_stop_times_from_stop('193a3ce3-b584-4bf6-92cc-ba08b23638ea'::uuid, 1, '2024-08-01 22:21+02');
