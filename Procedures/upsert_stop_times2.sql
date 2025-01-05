-- PROCEDURE: public.upsert_stop_times(stop_times2_type[])

-- DROP PROCEDURE IF EXISTS public.upsert_stop_times(stop_times2_type[]);

CREATE OR REPLACE PROCEDURE public.upsert_stop_times2(
    IN _stop_times stop_times_type[]
)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    INSERT INTO public.stop_times2 (
        data_origin, trip_id, stop_id, stop_sequence, arrival_time, departure_time, stop_headsign,
        pickup_type, drop_off_type, shape_dist_travelled, timepoint_type, internal_id, last_updated, import_id
    )
    SELECT DISTINCT
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
    FROM UNNEST(_stop_times) AS _stop_time;
END;
$BODY$;

ALTER PROCEDURE public.upsert_stop_times2(stop_times_type[])
    OWNER TO postgres;
