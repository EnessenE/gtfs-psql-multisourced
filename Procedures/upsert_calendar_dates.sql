-- Upsert Procedure for Calendar Dates
CREATE OR REPLACE PROCEDURE public.upsert_calendar_dates(
    calendar_dates public.calendar_dates_type
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.calendar_dates(
        data_origin, service_id, date, exception_type, internal_id, last_updated, import_id
    )
    SELECT data_origin, service_id, date, exception_type, internal_id, last_updated, import_id
    FROM calendar_dates
    ON CONFLICT(service_id, data_origin) DO UPDATE
    SET
        data_origin = EXCLUDED.data_origin,
        exception_type = EXCLUDED.exception_type,
        internal_id = EXCLUDED.internal_id,
        last_updated = EXCLUDED.last_updated,
        import_id = EXCLUDED.import_id;
END;
$$;