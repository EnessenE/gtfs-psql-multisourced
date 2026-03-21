DROP FUNCTION IF EXISTS get_route_from_id(text, text);

CREATE OR REPLACE FUNCTION public.get_route_from_id(target_data_origin text, target_route_id text)
    RETURNS TABLE(
        data_origin text,
        id text,
        agency text,
        short_name text,
        long_name text,
        description text,
        type text,
        url text,
        color text,
        text_color text,
        last_updated timestamp with time zone,
        stop_count integer,
        trip_count integer)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1
    AS $BODY$
    WITH matched_route AS (
        SELECT
            routes.id,
            routes.data_origin
        FROM
            routes
        WHERE
            routes.data_origin = target_data_origin
            AND (
                routes.id = target_route_id
                OR routes.short_name = target_route_id
            )
        ORDER BY
            CASE WHEN routes.id = target_route_id THEN 0 ELSE 1 END,
            routes.last_updated DESC
        LIMIT 1
    ),
    trip_count_data AS (
        SELECT
            COUNT(DISTINCT trips.id)::integer AS trip_count
        FROM
            trips
            INNER JOIN matched_route ON matched_route.data_origin = trips.data_origin
        WHERE
            trips.route_id = matched_route.id
    ),
    stop_count_data AS (
        SELECT
            COUNT(DISTINCT related_stops.primary_stop)::integer AS stop_count
        FROM
            trips
            INNER JOIN matched_route ON matched_route.data_origin = trips.data_origin
            INNER JOIN stop_times ON stop_times.trip_id = trips.id
                AND stop_times.data_origin = trips.data_origin
                AND stop_times.import_id = trips.import_id
            INNER JOIN stops ON stops.id = stop_times.stop_id
                AND stops.data_origin = stop_times.data_origin
                AND stops.import_id = stop_times.import_id
            INNER JOIN related_stops ON related_stops.related_stop = stops.internal_id
                AND related_stops.related_data_origin = stops.data_origin
        WHERE
            trips.route_id = matched_route.id
    )
    SELECT
        routes.data_origin,
        routes.id,
        COALESCE(agencies.name, 'Unknown agency'),
        routes.short_name,
        routes.long_name,
        routes.description,
        routes.type::text,
        routes.url,
        routes.color,
        routes.text_color,
        routes.last_updated,
        COALESCE(stop_count_data.stop_count, 0),
        COALESCE(trip_count_data.trip_count, 0)
    FROM
        matched_route
        INNER JOIN routes ON routes.id = matched_route.id
            AND routes.data_origin = matched_route.data_origin
        LEFT JOIN agencies ON agencies.id = routes.agency_id
            AND agencies.data_origin = routes.data_origin
        CROSS JOIN trip_count_data
        CROSS JOIN stop_count_data
    LIMIT 1
$BODY$;