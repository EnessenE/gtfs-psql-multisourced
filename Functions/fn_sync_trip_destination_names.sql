CREATE OR REPLACE FUNCTION public.fn_sync_trip_destination_names(target_data_origin text DEFAULT NULL)
RETURNS void 
LANGUAGE plpgsql
AS $BODY$
BEGIN
    -- Update trips in bulk
    UPDATE public.trips t
    SET destination_stop_name = last_stops.stop_name
    FROM (
        -- Subquery: Find the name of the stop with the highest sequence for each trip
        SELECT DISTINCT ON (st.trip_id, st.data_origin)
            st.trip_id,
            st.data_origin,
            s.name AS stop_name
        FROM public.stop_times st
        JOIN public.stops s ON s.id = st.stop_id AND s.data_origin = st.data_origin
        WHERE (target_data_origin IS NULL OR st.data_origin = target_data_origin)
        ORDER BY st.trip_id, st.data_origin, st.stop_sequence DESC
    ) AS last_stops
    WHERE t.id = last_stops.trip_id
      AND t.data_origin = last_stops.data_origin
      -- Condition: Only fallback if headsign is actually empty/null
      AND (t.headsign IS NULL OR t.headsign = '')
      -- Optional optimization: Only update if we haven't already calculated it
      AND t.destination_stop_name IS NULL;

    -- Update statistics for the planner
    ANALYZE public.trips;
END;
$BODY$;