-- PROCEDURE: public.upsert_stop_times2(stop_times_type[])

-- DROP PROCEDURE IF EXISTS public.upsert_stop_times2(stop_times_type[]);

CREATE OR REPLACE PROCEDURE public.upsert_stop_times2(
	IN _stop_times stop_times_type[])
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Use a simpler approach without temp tables that might be causing issues
    -- Insert directly with ON CONFLICT handling for upsert behavior

    -- Bulk insert data into the temporary table (much faster than row-by-row)
    -- Direct insertion with ON CONFLICT handling
    INSERT INTO public.stop_times2 (
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
        COALESCE(_stop_time.import_id, '00000000-0000-0000-0000-000000000000'::uuid)
    FROM UNNEST(_stop_times) AS _stop_time
    ON CONFLICT (data_origin, trip_id, stop_id, stop_sequence, import_id) 
    DO UPDATE SET
        arrival_time = EXCLUDED.arrival_time,
        departure_time = EXCLUDED.departure_time,
        stop_headsign = EXCLUDED.stop_headsign,
        pickup_type = EXCLUDED.pickup_type,
        drop_off_type = EXCLUDED.drop_off_type,
        shape_dist_travelled = EXCLUDED.shape_dist_travelled,
        timepoint_type = EXCLUDED.timepoint_type,
        internal_id = EXCLUDED.internal_id,
        last_updated = EXCLUDED.last_updated;
END;
$BODY$;
ALTER PROCEDURE public.upsert_stop_times2(stop_times_type[])
    OWNER TO postgres;
