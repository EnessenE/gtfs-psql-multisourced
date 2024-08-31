-- Table: public.supplier_type_mapping

-- DROP TABLE IF EXISTS public.supplier_type_mapping;

CREATE TABLE IF NOT EXISTS public.supplier_type_mappings
(
    supplier_configuration_name text COLLATE pg_catalog."default" NOT NULL,
    listed_type integer NOT NULL,
    new_type integer,
    CONSTRAINT supplier_type_mapping_pkey PRIMARY KEY (supplier_configuration_name, listed_type)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.supplier_type_mappings
    OWNER to postgres;