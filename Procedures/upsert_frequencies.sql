CREATE OR REPLACE PROCEDURE public.upsert_frequencies(
    frequencies public.frequencies_type
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.frequencies(
        data_origin, trip_id, start_time, end_time, headway_secs, exact_times, internal_id, last_updated, import_id
    )
    SELECT data_origin, trip_id, start_time, end_time, headway_secs, exact_times, internal_id, last_updated, import_id
    FROM frequencies
    ON CONFLICT(id, data_origin) DO UPDATE
    SET
        data_origin = EXCLUDED.data_origin,
        end_time = EXCLUDED.end_time,
        headway_secs = EXCLUDED.headway_secs,
        exact_times = EXCLUDED.exact_times,
        internal_id = EXCLUDED.internal_id,
        last_updated = EXCLUDED.last_updated,
        import_id = EXCLUDED.import_id;
END;
$$;