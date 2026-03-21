DROP FUNCTION IF EXISTS get_service_date_range_from_route(text, text);

CREATE OR REPLACE FUNCTION public.get_service_date_range_from_route(
    target_data_origin text,
    target_route_id text
)
RETURNS TABLE(first_run date, last_run date)
LANGUAGE 'sql'
COST 100 VOLATILE PARALLEL UNSAFE ROWS 1
AS $BODY$
    WITH matched_route AS (
        SELECT routes.id, routes.data_origin
        FROM routes
        WHERE routes.data_origin = target_data_origin
          AND (routes.id = target_route_id OR routes.short_name = target_route_id)
        ORDER BY CASE WHEN routes.id = target_route_id THEN 0 ELSE 1 END,
                 routes.last_updated DESC
        LIMIT 1
    ),
    route_service_ids AS (
        SELECT DISTINCT trips.service_id
        FROM trips
        INNER JOIN matched_route ON matched_route.data_origin = trips.data_origin
            AND trips.route_id = matched_route.id
        WHERE trips.service_id IS NOT NULL
    ),
    from_calendars AS (
        SELECT
            MIN(c.start_date) AS first_run,
            MAX(c.end_date)   AS last_run
        FROM calendars c
        INNER JOIN route_service_ids rs ON rs.service_id = c.service_id
        WHERE c.data_origin = target_data_origin
    ),
    from_calendar_dates AS (
        SELECT
            MIN(cd.date) AS first_run,
            MAX(cd.date) AS last_run
        FROM calendar_dates cd
        INNER JOIN route_service_ids rs ON rs.service_id = cd.service_id
        WHERE cd.data_origin = target_data_origin
          AND LOWER(cd.exception_type) = 'added'
    )
    SELECT
        LEAST(fc.first_run, fcd.first_run)      AS first_run,
        GREATEST(fc.last_run, fcd.last_run)     AS last_run
    FROM from_calendars fc
    CROSS JOIN from_calendar_dates fcd
$BODY$;
