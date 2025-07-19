DROP PROCEDURE IF EXISTS public.upsert_calenders;

CREATE OR REPLACE PROCEDURE public.upsert_calenders(
    _calendars public.calenders_type[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.calenders (
        data_origin,
        service_id,
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
    SELECT DISTINCT
        calendar.data_origin,
        calendar.service_id,
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
    FROM UNNEST(_calendars) AS calendar
    ON CONFLICT (data_origin, service_id) DO UPDATE
    SET
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
$$;
