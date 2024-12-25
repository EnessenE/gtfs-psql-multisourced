
-- Upsert Procedure for Stop Times
CREATE OR REPLACE PROCEDURE public.upsert_stop_times(
    stop_times public.stop_times_type
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.stop_times(
        data_origin, trip_id, stop_id, stop_sequence, arrival_time, departure_time, stop_headsign, pickup_type, drop_off_type, shape_dist_travelled, timepoint_type, internal_id, last_updated, import_id
    )
    SELECT data_origin, trip_id, stop_id, stop_sequence, arrival_time, departure_time, stop_headsign, pickup_type, drop_off_type, shape_dist_travelled, timepoint_type, internal_id, last_updated, import_id
    FROM stop_times
    ON CONFLICT(trip_id, stop_sequence) DO UPDATE
    SET
        data_origin = EXCLUDED.data_origin,
        stop_id = EXCLUDED.stop_id,
        arrival_time = EXCLUDED.arrival_time,
        departure_time = EXCLUDED.departure_time,
        stop_headsign = EXCLUDED.stop_headsign,
        pickup_type = EXCLUDED.pickup_type,
        drop_off_type = EXCLUDED.drop_off_type,
        shape_dist_travelled = EXCLUDED.shape_dist_travelled,
        timepoint_type = EXCLUDED.timepoint_type,
        internal_id = EXCLUDED.internal_id,
        last_updated = EXCLUDED.last_updated,
        import_id = EXCLUDED.import_id;
END;
$$;