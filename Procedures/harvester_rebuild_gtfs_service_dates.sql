CREATE OR REPLACE PROCEDURE public.harvester_rebuild_gtfs_service_dates(target_import_id uuid, target_origin text)
LANGUAGE plpgsql
AS $BODY$
BEGIN
    -- 1. Create handles from BOTH calendars AND calendar_dates 
    -- (Essential for sources like OpenOV that might not use calendars.txt)
    INSERT INTO public.gtfs_services (import_id, data_origin, service_id)
    SELECT DISTINCT target_import_id, target_origin, service_id
    FROM (
        SELECT service_id FROM public.calendars WHERE data_origin = target_origin
        UNION
        SELECT service_id FROM public.calendar_dates WHERE data_origin = target_origin
    ) AS all_services
    ON CONFLICT (import_id, service_id) DO NOTHING;

    -- 2. Link trips to the handles
    UPDATE public.trips t
    SET service_handle_id = s.service_handle_id
    FROM public.gtfs_services s
    WHERE t.service_id = s.service_id 
      AND t.data_origin = s.data_origin 
      AND s.import_id = target_import_id;

    -- 3. Explode calendars into individual dates
    INSERT INTO public.gtfs_service_dates (service_handle_id, service_date)
    SELECT 
        s.service_handle_id, 
        g.date::date
    FROM public.gtfs_services s
    JOIN public.calendars c ON s.service_id = c.service_id AND s.data_origin = c.data_origin
    CROSS JOIN LATERAL generate_series(c.start_date, c.end_date, '1 day'::interval) g(date)
    WHERE s.import_id = target_import_id
      AND (
        (EXTRACT(isodow FROM g.date) = 1 AND c.monday) OR
        (EXTRACT(isodow FROM g.date) = 2 AND c.tuesday) OR
        (EXTRACT(isodow FROM g.date) = 3 AND c.wednesday) OR
        (EXTRACT(isodow FROM g.date) = 4 AND c.thursday) OR
        (EXTRACT(isodow FROM g.date) = 5 AND c.friday) OR
        (EXTRACT(isodow FROM g.date) = 6 AND c.saturday) OR
        (EXTRACT(isodow FROM g.date) = 7 AND c.sunday)
      )
    ON CONFLICT DO NOTHING;

    -- 4. Add 'Added' exceptions
    INSERT INTO public.gtfs_service_dates (service_handle_id, service_date)
    SELECT s.service_handle_id, cd.date
    FROM public.gtfs_services s
    JOIN public.calendar_dates cd ON s.service_id = cd.service_id AND s.data_origin = cd.data_origin
    WHERE s.import_id = target_import_id 
      AND cd.exception_type = 'Added'
    ON CONFLICT DO NOTHING;

    -- 5. Remove 'Removed' exceptions
    DELETE FROM public.gtfs_service_dates gsd
    USING public.gtfs_services s, public.calendar_dates cd
    WHERE gsd.service_handle_id = s.service_handle_id
      AND s.service_id = cd.service_id 
      AND s.data_origin = cd.data_origin
      AND s.import_id = target_import_id
      AND gsd.service_date = cd.date
      AND cd.exception_type = 'Removed';

    -- 6. Sync Fallback Destination Names
    PERFORM public.fn_sync_trip_destination_names(target_origin);

    ANALYZE public.gtfs_service_dates;
    ANALYZE public.trips;
END;
$BODY$;