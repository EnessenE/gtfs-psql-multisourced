


DROP INDEX IF EXISTS public.ix_stops_parent_station;

DROP INDEX IF EXISTS public.ix_stops_name_stop_type;


DROP INDEX IF EXISTS public.ix_stop_times2_stop_id_data_origin;
DROP INDEX IF EXISTS public.ix_stop_times2_stop_id;
DROP INDEX IF EXISTS public.ix_agencies_internal_id;

DROP INDEX IF EXISTS ix_position_entities_trip_id_data_origin;
DROP INDEX IF EXISTS ix_routes_id_data_origin;
DROP INDEX IF EXISTS ix_trip_updates_stop_times_trip_id_data_origin_stop_id;
DROP INDEX IF EXISTS ix_trips_shape_id;
DROP INDEX IF EXISTS ix_calendar_dates_service_id_data_origin_date;
DROP INDEX IF EXISTS ix_calendar_dates_service_id_data_origin_date;
