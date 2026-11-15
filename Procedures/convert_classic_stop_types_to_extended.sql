-- One-time migration: convert all classic GTFS route/stop types (0-12) stored in
-- stops.stop_type and routes.type to their extended equivalents (100+), so every
-- stop type in the database is an extended type and serializes as a named
-- ExtendedRouteType (string) instead of a bare number.
-- Idempotent: rows already holding extended values are left untouched.

BEGIN;

UPDATE stops
SET stop_type = CASE stop_type
    WHEN 0 THEN 900   -- tram -> TramService
    WHEN 1 THEN 401   -- subway -> MetroService
    WHEN 2 THEN 100   -- rail -> RailwayService
    WHEN 3 THEN 700   -- bus -> BusService
    WHEN 4 THEN 1000  -- ferry -> WaterTransportService
    WHEN 5 THEN 1302  -- cable tram -> CableCarService
    WHEN 6 THEN 1300  -- aerial lift -> AerialLiftService
    WHEN 7 THEN 1400  -- funicular -> FunicularService
    WHEN 11 THEN 800  -- trolleybus -> TrolleybusService
    WHEN 12 THEN 405  -- monorail -> Monorail
    ELSE stop_type
END
WHERE stop_type IN (0, 1, 2, 3, 4, 5, 6, 7, 11, 12);

UPDATE routes
SET type = CASE type
    WHEN 0 THEN 900
    WHEN 1 THEN 401
    WHEN 2 THEN 100
    WHEN 3 THEN 700
    WHEN 4 THEN 1000
    WHEN 5 THEN 1302
    WHEN 6 THEN 1300
    WHEN 7 THEN 1400
    WHEN 11 THEN 800
    WHEN 12 THEN 405
    ELSE type
END
WHERE type IN (0, 1, 2, 3, 4, 5, 6, 7, 11, 12);

COMMIT;
