CREATE OR REPLACE PROCEDURE public.upsert_stop_times(
    IN _stop_times public.stop_times_type[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.stop_times (
        data_origin,
        trip_id,
        stop_id,
        stop_sequence,
        arrival_time,
        departure_time,
        days_since_start_arrival,
        days_since_start_departure,
        stop_headsign,
        pickup_type,
        drop_off_type,
        shape_dist_travelled,
        timepoint_type,
        last_updated,
        import_id
    )
    SELECT DISTINCT
        st.data_origin,
        st.trip_id,
        st.stop_id,
        st.stop_sequence_data::bigint,
        st.arrival_time_data,
        st.departure_time_data,
        COALESCE(st.days_since_start_arrival, 0),
        COALESCE(st.days_since_start_departure, 0),
        st.stop_headsign,
        st.pickup_type_data,
        st.drop_off_type_data,
        st.shape_dist_travelled,
        st.timepoint_type_data,
        st.last_updated,
        st.import_id
    FROM UNNEST(_stop_times) AS st
    ON CONFLICT (data_origin, trip_id, stop_id, stop_sequence, import_id)
    DO NOTHING;
END;
$$;

ALTER PROCEDURE public.upsert_stop_times(public.stop_times_type[])
OWNER TO postgres;
