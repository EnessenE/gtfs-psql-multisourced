CREATE OR REPLACE PROCEDURE public.upsert_frequencies(
    _frequencies public.frequencies_type[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.frequencies(
        data_origin, trip_id, start_time, end_time, headway_secs, exact_times, internal_id, last_updated, import_id
    )
    SELECT
        _frequency.data_origin,
        _frequency.trip_id,
        _frequency.start_time_data,
        _frequency.end_time_data,
        _frequency.headway_secs,
        _frequency.exact_times_data,
        _frequency.internal_id,
        _frequency.last_updated,
        _frequency.import_id
    FROM UNNEST(_frequencies) AS _frequency
    ON CONFLICT (data_origin, trip_id, start_time, end_time) DO UPDATE
    SET
        headway_secs = EXCLUDED.headway_secs,
        exact_times = EXCLUDED.exact_times,
        internal_id = EXCLUDED.internal_id,
        last_updated = EXCLUDED.last_updated,
        import_id = EXCLUDED.import_id;
END;
$$;

ALTER PROCEDURE public.upsert_frequencies(public.frequencies_type[])
    OWNER TO postgres;
