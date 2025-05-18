CREATE OR REPLACE PROCEDURE public.merge_stop(IN target text, IN supplier text) 
LANGUAGE plpgsql
AS $BODY$
DECLARE
    stopdata RECORD;
    chosen_guid uuid;
    v_target_geo geometry;
    v_target_name text;
    v_target_parent text;
BEGIN
    -- Generate a GUID for this merge group
    SELECT uuid_generate_v4() INTO chosen_guid;

    -- Retrieve the target stop info
    SELECT *
    INTO stopdata
    FROM public.stops
    WHERE id = target
      AND data_origin = supplier;

    IF NOT FOUND THEN
        RAISE NOTICE 'Target stop not found.';
        RETURN;
    END IF;

    -- Check if already merged
    IF EXISTS (
         SELECT 1
         FROM public.related_stops
         WHERE related_stop = stopdata.internal_id
    ) THEN
         RAISE NOTICE 'Target stop already related.';
         RETURN;
    END IF;

    -- Cache relevant fields
    v_target_geo    := stopdata.geo_location;
    v_target_name   := stopdata.name;
    v_target_parent := stopdata.parent_station;

    -- Perform spatial and parent/child-based match
    WITH candidates AS (
        SELECT s.internal_id, s.data_origin
        FROM public.stops s
        WHERE
            (
                -- Parent/child match, only if data_origin is the same
                (v_target_parent IS NOT NULL AND v_target_parent <> '' AND s.data_origin = stopdata.data_origin AND (s.id = v_target_parent OR v_target_parent = s.parent_station))
            )
            OR (
                -- Spatial pre-filter (bounding box)
                s.geo_location && ST_Expand(v_target_geo, 300)
                AND (
                    ST_DWithin(s.geo_location, v_target_geo, 75, FALSE)
                    OR (
                        ST_DWithin(s.geo_location, v_target_geo, 300, FALSE)
                        AND SIMILARITY(s.name, v_target_name) >= 0.2
                    )
                )
                AND (v_target_parent IS NULL OR v_target_parent = '')
            )
    )
    INSERT INTO public.related_stops(primary_stop, related_stop, related_data_origin)
    SELECT chosen_guid, internal_id, data_origin
    FROM candidates
    ON CONFLICT DO NOTHING;

    -- Insert target stop itself if not present
    IF NOT EXISTS (
         SELECT 1 FROM public.related_stops WHERE related_stop = stopdata.internal_id
    ) THEN
        INSERT INTO public.related_stops(primary_stop, related_stop, related_data_origin)
        VALUES (chosen_guid, stopdata.internal_id, stopdata.data_origin)
        ON CONFLICT DO NOTHING;
    END IF;
END;
$BODY$;

ALTER PROCEDURE public.merge_stop(text, text) OWNER TO dennis;
