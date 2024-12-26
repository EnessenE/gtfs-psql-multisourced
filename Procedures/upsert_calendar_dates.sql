DROP PROCEDURE IF EXISTS public.upsert_calendar_dates;

CREATE OR REPLACE PROCEDURE public.upsert_calendar_dates(
    _calendar_dates public.calendar_dates_type[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.calendar_dates(
        data_origin, service_id, date, exception_type, internal_id, last_updated, import_id
    )
    SELECT 
        _calendar_date.data_origin, 
        _calendar_date.service_id, 
        _calendar_date.date, 
        _calendar_date.exception_type_data, 
        _calendar_date.internal_id, 
        _calendar_date.last_updated, 
        _calendar_date.import_id
    FROM UNNEST(_calendar_dates) AS _calendar_date
    ON CONFLICT(data_origin, date, service_id) DO UPDATE
    SET
        data_origin = EXCLUDED.data_origin,
        date = EXCLUDED.date,
        exception_type = EXCLUDED.exception_type,
        internal_id = EXCLUDED.internal_id,
        last_updated = EXCLUDED.last_updated,
        import_id = EXCLUDED.import_id;
END;
$$;
