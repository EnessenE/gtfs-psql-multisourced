-- Upsert procedure for calendar
CREATE OR REPLACE PROCEDURE public.upsert_calenders(calendars public.calenders_type[])
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.calenders (
        data_origin,
        service_id,
		mask,
        monday,
        tuesday,
        wednesday,
        thursday,
        friday,
        saturday,
        sunday,
        start_date,
        end_date,
        internal_id,
        last_updated,
        import_id
    )
    SELECT 
        calendar.data_origin,
        calendar.service_id,
        calendar.mask,
        calendar.monday,
        calendar.tuesday,
        calendar.wednesday,
        calendar.thursday,
        calendar.friday,
        calendar.saturday,
        calendar.sunday,
        calendar.start_date,
        calendar.end_date,
        calendar.internal_id,
        calendar.last_updated,
        calendar.import_id
    FROM unnest(calendars) AS calendar
    ON CONFLICT (data_origin, service_id) -- Assuming 'service_id' is the unique key
    DO UPDATE SET
        data_origin = EXCLUDED.data_origin,
        mask = EXCLUDED.mask,
        monday = EXCLUDED.monday,
        tuesday = EXCLUDED.tuesday,
        wednesday = EXCLUDED.wednesday,
        thursday = EXCLUDED.thursday,
        friday = EXCLUDED.friday,
        saturday = EXCLUDED.saturday,
        sunday = EXCLUDED.sunday,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        internal_id = EXCLUDED.internal_id,
        last_updated = EXCLUDED.last_updated,
        import_id = EXCLUDED.import_id;
END;
$$
