CREATE OR REPLACE PROCEDURE upsert_alert_update_array(IN updates alert_update[])
LANGUAGE plpgsql
AS $$
DECLARE
    update_item alert_update;
BEGIN
    -- Loop through the array of alert_update
    FOREACH update_item IN ARRAY updates LOOP
        INSERT INTO alerts(id, data_origin, internal_id, last_updated, effect, cause, severity_level, url, header_text, description_text)
            VALUES (
                update_item.id,
                update_item.data_origin,
                update_item.internal_id,
                update_item.last_updated,
                update_item.effect,
                update_item.cause,
                update_item.severity_level,
                update_item.url,
                update_item.header_text,
                update_item.description_text
            )
        ON CONFLICT (id, data_origin)
            DO UPDATE SET
                last_updated = EXCLUDED.last_updated,
                effect = EXCLUDED.effect,
                cause = EXCLUDED.cause,
                severity_level = EXCLUDED.severity_level,
                url = EXCLUDED.url,
                header_text = EXCLUDED.header_text,
                description_text = EXCLUDED.description_text;
    END LOOP;
END
$$;
