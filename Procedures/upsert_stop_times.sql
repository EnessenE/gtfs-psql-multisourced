DROP PROCEDURE IF EXISTS public.upsert_stop_times;

CREATE OR REPLACE PROCEDURE public.upsert_stop_times(
    _stop_times public.stop_times_type[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Use an array of DISTINCT entries and insert/update using ON CONFLICT
    INSERT INTO public.stop_times(
        data_origin, trip_id, stop_id, stop_sequence, arrival_time, departure_time, stop_headsign,
        pickup_type, drop_off_type, shape_dist_travelled, timepoint_type, internal_id, last_updated, import_id
    )
    SELECT 
        _stop_time.data_origin, 
        _stop_time.trip_id, 
        _stop_time.stop_id, 
        _stop_time.stop_sequence_data, 
        _stop_time.arrival_time, 
        _stop_time.departure_time, 
        _stop_time.stop_headsign, 
        _stop_time.pickup_type_data, 
        _stop_time.drop_off_type_data, 
        _stop_time.shape_dist_travelled, 
        _stop_time.timepoint_type_data, 
        _stop_time.internal_id, 
        _stop_time.last_updated, 
        _stop_time.import_id
    FROM UNNEST(_stop_times) AS _stop_time
    ON CONFLICT (data_origin, trip_id, stop_id, stop_sequence) 
    DO UPDATE SET
        arrival_time = EXCLUDED.arrival_time,
        departure_time = EXCLUDED.departure_time,
        stop_headsign = EXCLUDED.stop_headsign,
        pickup_type = EXCLUDED.pickup_type,
        drop_off_type = EXCLUDED.drop_off_type,
        shape_dist_travelled = EXCLUDED.shape_dist_travelled,
        timepoint_type = EXCLUDED.timepoint_type,
        internal_id = EXCLUDED.internal_id,
        last_updated = EXCLUDED.last_updated,
        import_id = EXCLUDED.import_id
    WHERE 
        stop_times.arrival_time IS DISTINCT FROM EXCLUDED.arrival_time OR
        stop_times.departure_time IS DISTINCT FROM EXCLUDED.departure_time OR
        stop_times.stop_headsign IS DISTINCT FROM EXCLUDED.stop_headsign OR
        stop_times.pickup_type IS DISTINCT FROM EXCLUDED.pickup_type OR
        stop_times.drop_off_type IS DISTINCT FROM EXCLUDED.drop_off_type OR
        stop_times.shape_dist_travelled IS DISTINCT FROM EXCLUDED.shape_dist_travelled OR
        stop_times.timepoint_type IS DISTINCT FROM EXCLUDED.timepoint_type OR
        stop_times.internal_id IS DISTINCT FROM EXCLUDED.internal_id OR
        stop_times.last_updated IS DISTINCT FROM EXCLUDED.last_updated OR
        stop_times.import_id IS DISTINCT FROM EXCLUDED.import_id;
END;
$$;
