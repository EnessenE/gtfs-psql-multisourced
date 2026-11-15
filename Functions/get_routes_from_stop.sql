-- FUNCTION: public.get_routes_from_stop(uuid, integer)
-- DROP FUNCTION IF EXISTS public.get_routes_from_stop(uuid, integer);
DROP FUNCTION IF EXISTS public.get_routes_from_stop(text, integer);

CREATE OR REPLACE FUNCTION public.get_routes_from_stop(target text, target_stop_type integer)
    RETURNS TABLE(
        id text,
        data_origin text,
        agency text,
        short_name text,
        long_name text,
        description text,
        type text,
        url text,
        color text,
        text_color text,
        import_id uuid)
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    WITH primary_stop_data AS(
        SELECT
            stops.id,
            stops.data_origin
        FROM
            stops
            INNER JOIN related_stops ON related_stops.related_stop = stops.internal_id
        WHERE
            primary_stop = target::uuid
            AND stop_type = target_stop_type
),
-- plain joins (with LATERAL so the planner uses the stop_id/trip_id indexes per
-- parameter row) instead of row-value IN subqueries, which it resolves with
-- sequential scans of stop_times/trips (several seconds at busy stops)
stop_data AS MATERIALIZED(
    SELECT DISTINCT
        st.trip_id,
        st.data_origin
    FROM
        primary_stop_data p
        CROSS JOIN LATERAL (
            SELECT stop_times.trip_id, stop_times.data_origin
            FROM stop_times
            WHERE stop_times.stop_id = p.id
                AND stop_times.data_origin = p.data_origin
        ) st
),
trip_data AS MATERIALIZED(
    SELECT DISTINCT
        t.route_id,
        t.data_origin
    FROM
        stop_data s
        CROSS JOIN LATERAL (
            SELECT trips.route_id, trips.data_origin
            FROM trips
            WHERE trips.id = s.trip_id
                AND trips.data_origin = s.data_origin
        ) t
)
SELECT
    routes.id,
    routes.data_origin,
    COALESCE(agencies.name, 'Unknown agency'),
    short_name,
    long_name,
    description,
    type,
    routes.url,
    color,
    text_color,
    routes.import_id
FROM
    routes
    INNER JOIN trip_data ON trip_data.route_id = routes.id
        AND trip_data.data_origin = routes.data_origin
    LEFT JOIN agencies ON agencies.id = routes.agency_id
        AND agencies.data_origin = routes.data_origin
GROUP BY
    routes.id,
    routes.data_origin,
    COALESCE(agencies.name, 'Unknown agency'),
    short_name,
    long_name,
    description,
    type,
    routes.url,
    color,
    text_color,
    routes.import_id
ORDER BY
    short_name ASC
$BODY$;
