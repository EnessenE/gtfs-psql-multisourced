DROP PROCEDURE IF EXISTS public.upsert_stop_times;

CREATE OR REPLACE PROCEDURE public.upsert_stop_times(
    _stop_times public.stop_times_type[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.stop_times(
        data_origin, trip_id, stop_id, stop_sequence, arrival_time, departure_time, stop_headsign, pickup_type, drop_off_type, shape_dist_travelled, timepoint_type, internal_id, last_updated, import_id
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
    ON CONFLICT(data_origin, trip_id, stop_id, stop_sequence) DO UPDATE
    SET
        data_origin = EXCLUDED.data_origin,
        stop_id = EXCLUDED.stop_id,
        stop_sequence = EXCLUDED.stop_sequence,
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
