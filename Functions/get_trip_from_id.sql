
DROP FUNCTION IF EXISTS public.get_trip_from_id(target uuid);
CREATE OR REPLACE FUNCTION public.get_trip_from_id(target uuid)

    RETURNS TABLE(
        id text,
        route_id text,
        service_id text,
        headsign text,
        short_name text,
        direction int,
        block_id text,
        data_origin text,
        latitude double precision,
        longitude double precision,
        current_status text,
        congestion_level text,
        occupancy_status text,
        occupancy_percentage integer,
        measurement_time timestamp with time zone,
        enroute_to text,
        target_stop_id text,
        target_stop text,
        route_short_name text,
        route_long_name text,
        stop_sequence int,
        stop_id text,
        stop_name text,
        arrival_time timestamp with time zone,
        departure_time timestamp with time zone,
        passthrough boolean,
        extra_stop boolean,
        schedule_relationship text
    )
    LANGUAGE 'sql'
    COST 100 VOLATILE PARALLEL UNSAFE ROWS 1000
    AS $BODY$
    SELECT * FROM (
        SELECT
            trips.id,
            trips.route_id,
            trips.service_id,
            trips.headsign,
            trips.short_name,
            trips.direction,
            trips.block_id,
            trips.data_origin,
            position_entities.latitude,
            position_entities.longitude,
            position_entities.current_status,
            position_entities.congestion_level,
            position_entities.occupancy_status,
            position_entities.occupancy_percentage,
            position_entities.measurement_time,
            (select primary_stop from related_stops inner join stops s2 on s2.internal_id = related_stops.related_stop where s2.id = position_entities.stop_id and s2.data_origin = trips.data_origin limit 1),
            stops.internal_id::text,
            stops.name,
            routes.short_name,
            routes.long_name,
            st.stop_sequence,
            st.stop_id,
            st_stop.name as stop_name,
            tus.arrival_time,
            tus.departure_time,
            (tus.arrival_time IS NULL AND tus.departure_time IS NULL) AS passthrough,
            false as extra_stop,
            tus.schedule_relationship
        FROM
            trips
        LEFT JOIN routes ON routes.data_origin = trips.data_origin AND routes.id = trips.route_id
        LEFT JOIN position_entities ON position_entities.data_origin = trips.data_origin AND position_entities.trip_id = trips.id
        LEFT JOIN stops ON stops.data_origin = trips.data_origin AND position_entities.stop_id = stops.id
        LEFT JOIN stop_times st ON st.data_origin = trips.data_origin AND st.trip_id = trips.id
        LEFT JOIN stops st_stop ON st_stop.data_origin = st.data_origin AND st_stop.id = st.stop_id
        LEFT JOIN trip_updates_stop_times tus ON tus.data_origin = trips.data_origin AND tus.trip_id = trips.id AND tus.stop_id = st.stop_id
        WHERE
            trips.internal_id = target
        UNION
        SELECT
            trips.id,
            trips.route_id,
            trips.service_id,
            trips.headsign,
            trips.short_name,
            trips.direction,
            trips.block_id,
            trips.data_origin,
            position_entities.latitude,
            position_entities.longitude,
            position_entities.current_status,
            position_entities.congestion_level,
            position_entities.occupancy_status,
            position_entities.occupancy_percentage,
            position_entities.measurement_time,
            (select primary_stop from related_stops inner join stops s2 on s2.internal_id = related_stops.related_stop where s2.id = position_entities.stop_id and s2.data_origin = trips.data_origin limit 1),
            stops.internal_id::text,
            stops.name,
            routes.short_name,
            routes.long_name,
            tus.stop_sequence,
            tus.stop_id,
            st_stop.name as stop_name,
            tus.arrival_time,
            tus.departure_time,
            (tus.arrival_time IS NULL AND tus.departure_time IS NULL) AS passthrough,
            true as extra_stop,
            tus.schedule_relationship
        FROM
            trips
        LEFT JOIN routes ON routes.data_origin = trips.data_origin AND routes.id = trips.route_id
        LEFT JOIN position_entities ON position_entities.data_origin = trips.data_origin AND position_entities.trip_id = trips.id
        LEFT JOIN stops ON stops.data_origin = trips.data_origin AND position_entities.stop_id = stops.id
        LEFT JOIN trip_updates_stop_times tus ON tus.data_origin = trips.data_origin AND tus.trip_id = trips.id
        LEFT JOIN stops st_stop ON st_stop.data_origin = tus.data_origin AND st_stop.id = tus.stop_id
        LEFT JOIN stop_times st ON st.data_origin = tus.data_origin AND st.trip_id = tus.trip_id AND st.stop_id = tus.stop_id
        WHERE
            trips.internal_id = target
            AND st.stop_id IS NULL
            AND tus.stop_sequence is not null
    ) t
    ORDER BY COALESCE(t.stop_sequence, 999999), t.stop_id
$BODY$;

select * from get_trip_from_id('3d0798ed-96a9-4210-b0bb-9c1acaa80ab9');