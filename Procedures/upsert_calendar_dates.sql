-- PROCEDURE: public.upsert_calendar_dates(calendar_dates_type[])

-- DROP PROCEDURE IF EXISTS public.upsert_calendar_dates(calendar_dates_type[]);

CREATE OR REPLACE PROCEDURE public.upsert_calendar_dates(
    IN _calendar_dates public.calendar_dates_type[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.calendar_dates (
        data_origin, service_id, date, exception_type, internal_id, last_updated, import_id
    )
    SELECT DISTINCT
        _calendar_date.data_origin, 
        _calendar_date.service_id, 
        _calendar_date.date, 
        _calendar_date.exception_type_data,
        _calendar_date.internal_id, 
        _calendar_date.last_updated, 
        _calendar_date.import_id
    FROM UNNEST(_calendar_dates) AS _calendar_date
    ON CONFLICT (data_origin, service_id, date, import_id)
    DO NOTHING;  -- Ignore the conflict, effectively skipping duplicate entries
END;
$$;

ALTER PROCEDURE public.upsert_calendar_dates(calendar_dates_type[])
    OWNER TO postgres;
