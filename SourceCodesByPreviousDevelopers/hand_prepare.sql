CREATE SCHEMA IF NOT EXISTS hand AUTHORIZATION postgres;

DROP TABLE IF EXISTS hand.torename, hand.todelete, hand.forts, hand.buildings, hand.settlements, hand.regions, hand.parks, hand.square, hand.island, hand.railway_point, hand.roads, hand.milestone_point;

DROP FUNCTION IF EXISTS hand.before_insert_dt();
DROP FUNCTION IF EXISTS hand.bi_roadtype();
DROP FUNCTION IF EXISTS hand.before_update_dt();

-- Создание триггерной функции 
CREATE FUNCTION hand.before_insert_dt () RETURNS trigger AS '
BEGIN
     NEW.insert_dt := current_timestamp;
     NEW.update_dt := current_timestamp;
     RETURN NEW;
END;
' LANGUAGE  plpgsql;

CREATE FUNCTION hand.bi_roadtype () RETURNS trigger AS '
BEGIN
     NEW.roadtype := ''handadd'';
     RETURN NEW;
END;
' LANGUAGE  plpgsql;

CREATE FUNCTION hand.before_update_dt () RETURNS trigger AS '
BEGIN
     NEW.update_dt := current_timestamp;
     RETURN NEW;
END;
' LANGUAGE  plpgsql;

--------------------------------------------------------------------------------------


CREATE TABLE hand.torename
(
    gid  uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    tablename text,
    fieldname text,
    oldname text,
    newname text,
    insert_dt timestamp with time zone,
    update_dt timestamp with time zone,
    CONSTRAINT torename_pkey PRIMARY KEY (gid)
);

ALTER TABLE hand.torename OWNER to postgres;

DROP TRIGGER IF EXISTS before_insert_dt ON hand.torename;
DROP TRIGGER IF EXISTS before_update_dt ON hand.torename;

CREATE TRIGGER before_insert_dt
before INSERT ON hand.torename FOR EACH ROW
EXECUTE PROCEDURE hand.before_insert_dt();

CREATE TRIGGER before_update_dt
before UPDATE ON hand.torename FOR EACH ROW
EXECUTE PROCEDURE hand.before_update_dt();

DO $$ 
    BEGIN
	RAISE INFO 'Построили таблицу переименований.';
    END;
$$;

--------------------------------------------------------------------------------------
-- Строим таблицу подлежащего удалению из osm

CREATE TABLE hand.todelete
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    tablename text,
    insert_dt timestamp with time zone,
    update_dt timestamp with time zone,
    CONSTRAINT todelete_pkey PRIMARY KEY (gid)
);

ALTER TABLE hand.todelete OWNER to postgres;

DROP TRIGGER IF EXISTS before_insert_dt ON hand.todelete;
DROP TRIGGER IF EXISTS before_update_dt ON hand.todelete;

CREATE TRIGGER before_insert_dt
before INSERT ON hand.todelete FOR EACH ROW
EXECUTE PROCEDURE hand.before_insert_dt();

CREATE TRIGGER before_update_dt
before UPDATE ON hand.todelete FOR EACH ROW
EXECUTE PROCEDURE hand.before_update_dt();

DO $$ 
    BEGIN
	RAISE INFO 'Построили таблицу удалений.';
    END;
$$;

--------------------------------------------------------------------------------------
-- Строим таблицу Фортов hand.forts

CREATE TABLE hand.forts
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    addr_housenumber text,
    addr_street text,
    name text,
    name_ru text,
    geom geometry(Geometry,3857),
    insert_dt timestamp with time zone,
    update_dt timestamp with time zone,
    CONSTRAINT forts_pkey PRIMARY KEY (gid)
);

ALTER TABLE hand.forts OWNER to postgres;

DROP TRIGGER IF EXISTS before_insert_dt ON hand.forts;
DROP TRIGGER IF EXISTS before_update_dt ON hand.forts;

CREATE TRIGGER before_insert_dt
before INSERT ON hand.forts FOR EACH ROW
EXECUTE PROCEDURE hand.before_insert_dt();

CREATE TRIGGER before_update_dt
before UPDATE ON hand.forts FOR EACH ROW
EXECUTE PROCEDURE hand.before_update_dt();

DO $$ 
    BEGIN
	RAISE INFO 'Построили таблицу фортов.';
    END;
$$;

--------------------------------------------------------------------------------------
-- Строим таблицу Воды hand.water

CREATE TABLE hand.water
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    name text,
    name_ru text,
    geom geometry(Geometry,3857),
    insert_dt timestamp with time zone,
    update_dt timestamp with time zone,
    CONSTRAINT water_pkey PRIMARY KEY (gid)
);

ALTER TABLE hand.water OWNER to postgres;

DROP TRIGGER IF EXISTS before_insert_dt ON hand.water;
DROP TRIGGER IF EXISTS before_update_dt ON hand.water;

CREATE TRIGGER before_insert_dt
before INSERT ON hand.water FOR EACH ROW
EXECUTE PROCEDURE hand.before_insert_dt();

CREATE TRIGGER before_update_dt
before UPDATE ON hand.water FOR EACH ROW
EXECUTE PROCEDURE hand.before_update_dt();

DO $$ 
    BEGIN
	RAISE INFO 'Построили таблицу воды.';
    END;
$$;

--------------------------------------------------------------------------------------

-- Строим таблицу Строений (домов) hand.buildings

CREATE TABLE hand.buildings
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    addr_housenumber text,
    addr_street text,
    buildingtype text,
    name text,
    name_ru text,
    geom geometry(Geometry,3857),
    insert_dt timestamp with time zone,
    update_dt timestamp with time zone,
    CONSTRAINT buildings_pkey PRIMARY KEY (gid)
);

ALTER TABLE hand.buildings OWNER to postgres;

DROP TRIGGER IF EXISTS before_insert_dt ON hand.buildings;
DROP TRIGGER IF EXISTS before_update_dt ON hand.buildings;

CREATE TRIGGER before_insert_dt
before INSERT ON hand.buildings FOR EACH ROW
EXECUTE PROCEDURE hand.before_insert_dt();

CREATE TRIGGER before_update_dt
before UPDATE ON hand.buildings FOR EACH ROW
EXECUTE PROCEDURE hand.before_update_dt();

DO $$ 
    BEGIN
	RAISE INFO 'Построили таблицу Строений (домов).';
    END;
$$;

--------------------------------------------------------------------------------------
-- Строим таблицу Населенных пунктов 

CREATE TABLE hand.settlements
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    name text,
    name_ru text,
    place text,
    admin_level smallint,
    geom geometry(Geometry,3857),
    insert_dt timestamp with time zone,
    update_dt timestamp with time zone,
    CONSTRAINT settlements_pkey PRIMARY KEY (gid)
);
                       
ALTER TABLE hand.settlements OWNER to postgres;
                       
DROP TRIGGER IF EXISTS before_insert_dt ON hand.settlements;
DROP TRIGGER IF EXISTS before_update_dt ON hand.settlements;

CREATE TRIGGER before_insert_dt
before INSERT ON hand.settlements FOR EACH ROW
EXECUTE PROCEDURE hand.before_insert_dt();

CREATE TRIGGER before_update_dt
before UPDATE ON hand.settlements FOR EACH ROW
EXECUTE PROCEDURE hand.before_update_dt();

DO $$     
    BEGIN
	RAISE INFO 'Построили таблицу Населенных пунктов.';
    END;
$$;

--------------------------------------------------------------------------------------
-- Строим таблицу Районов, округов

CREATE TABLE hand.regions
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    admin_level smallint,
    name text,
    name_ru text,
    geom geometry(Geometry,3857),
    insert_dt timestamp with time zone,
    update_dt timestamp with time zone,
    CONSTRAINT regions_pkey PRIMARY KEY (gid)
);

ALTER TABLE hand.regions OWNER to postgres;                                           
                        
DROP TRIGGER IF EXISTS before_insert_dt ON hand.regions;
DROP TRIGGER IF EXISTS before_update_dt ON hand.regions;

CREATE TRIGGER before_insert_dt
before INSERT ON hand.regions FOR EACH ROW
EXECUTE PROCEDURE hand.before_insert_dt();

CREATE TRIGGER before_update_dt
before UPDATE ON hand.regions FOR EACH ROW
EXECUTE PROCEDURE hand.before_update_dt();

DO $$ 
    BEGIN
	RAISE INFO 'Построили таблицу Районов, округов.';
    END;
$$;

--------------------------------------------------------------------------------------
-- Строим таблицу Парков

CREATE TABLE hand.parks
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    name text,
    name_ru text,
    geom geometry(Geometry,3857),
    insert_dt timestamp with time zone,
    update_dt timestamp with time zone,
    CONSTRAINT parks_pkey PRIMARY KEY (gid)
);

ALTER TABLE hand.parks OWNER to postgres;                                          
                          
DROP TRIGGER IF EXISTS before_insert_dt ON hand.parks;
DROP TRIGGER IF EXISTS before_update_dt ON hand.parks;
                          
CREATE TRIGGER parks_before_insert_dt
before INSERT ON hand.parks FOR EACH ROW
EXECUTE PROCEDURE hand.before_insert_dt();

CREATE TRIGGER before_update_dt
before UPDATE ON hand.parks FOR EACH ROW
EXECUTE PROCEDURE hand.before_update_dt();

DO $$ 
    BEGIN
	RAISE INFO 'Построили таблицу Парков.';
    END;
$$;

--------------------------------------------------------------------------------------
-- Строим таблицу Площадей

CREATE TABLE hand.square
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    name text,
    name_ru text,
    geom geometry(Geometry,3857),
    insert_dt timestamp with time zone,
    update_dt timestamp with time zone,
    CONSTRAINT square_pkey PRIMARY KEY (gid)
);

ALTER TABLE hand.square OWNER to postgres;                                          

DROP TRIGGER IF EXISTS before_insert_dt ON hand.square;
DROP TRIGGER IF EXISTS before_update_dt ON hand.square;

CREATE TRIGGER before_insert_dt
before INSERT ON hand.square FOR EACH ROW
EXECUTE PROCEDURE hand.before_insert_dt();

CREATE TRIGGER before_update_dt
before UPDATE ON hand.square FOR EACH ROW
EXECUTE PROCEDURE hand.before_update_dt();

DO $$ 
    BEGIN
	RAISE INFO 'Построили таблицу Площадей.';
    END;
$$;

--------------------------------------------------------------------------------------
-- Строим таблицу Островов

CREATE TABLE hand.island
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    name text,
    name_ru text,
    geom geometry(Geometry,3857),
    insert_dt timestamp with time zone,
    update_dt timestamp with time zone,
    CONSTRAINT island_pkey PRIMARY KEY (gid)
);

ALTER TABLE hand.island OWNER to postgres;                                          

DROP TRIGGER IF EXISTS before_insert_dt ON hand.island;
DROP TRIGGER IF EXISTS before_update_dt ON hand.island;

CREATE TRIGGER before_insert_dt
before INSERT ON hand.island FOR EACH ROW
EXECUTE PROCEDURE hand.before_insert_dt();

CREATE TRIGGER before_update_dt
before UPDATE ON hand.island FOR EACH ROW
EXECUTE PROCEDURE hand.before_update_dt();

DO $$ 
    BEGIN
	RAISE INFO 'Построили таблицу Островов.';
    END;
$$;

--------------------------------------------------------------------------------------
-- Строим таблицу ЖД и метро станций

CREATE TABLE hand.railway_point
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_housenumber text,
    addr_street text,
    name text,
    name_ru text,
    geom geometry(Geometry,3857),
    insert_dt timestamp with time zone,
    update_dt timestamp with time zone,
    CONSTRAINT railway_point_pkey PRIMARY KEY (gid)
);

ALTER TABLE hand.railway_point OWNER to postgres;                                          

DROP TRIGGER IF EXISTS before_insert_dt ON hand.railway_point;
DROP TRIGGER IF EXISTS before_update_dt ON hand.railway_point;

CREATE TRIGGER before_insert_dt
before INSERT ON hand.railway_point FOR EACH ROW
EXECUTE PROCEDURE hand.before_insert_dt();

CREATE TRIGGER before_update_dt
before UPDATE ON hand.railway_point FOR EACH ROW
EXECUTE PROCEDURE hand.before_update_dt();

DO $$ 
    BEGIN
	RAISE INFO 'Построили таблицу ЖД.';
    END;
$$;

--------------------------------------------------------------------------------------
-- Строим таблицу дорог

CREATE TABLE hand.roads
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    name text,
    name_ru text,
    roadtype text,
    geom geometry(Geometry,3857),
    insert_dt timestamp with time zone,
    update_dt timestamp with time zone,
    CONSTRAINT roads_pkey PRIMARY KEY (gid)
);

ALTER TABLE hand.roads OWNER to postgres;                                          

DROP TRIGGER IF EXISTS before_insert_dt ON hand.roads;
DROP TRIGGER IF EXISTS before_update_dt ON hand.roads;
DROP TRIGGER IF EXISTS bi_roadtype ON hand.roads;

CREATE TRIGGER before_insert_dt
before INSERT ON hand.roads FOR EACH ROW
EXECUTE PROCEDURE hand.before_insert_dt();

CREATE TRIGGER before_update_dt
before UPDATE ON hand.roads FOR EACH ROW
EXECUTE PROCEDURE hand.before_update_dt();

CREATE TRIGGER bi_roadtype
before INSERT or UPDATE ON hand.roads FOR EACH ROW
EXECUTE PROCEDURE hand.bi_roadtype();

DO $$ 
    BEGIN
	RAISE INFO 'Построили таблицу Дорог.';
    END;
$$;

--------------------------------------------------------------------------------------
-- Строим таблицу Километровых столбов

CREATE TABLE hand.milestone_point
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    distance text,
    name text,
    name_ru text,
    geom geometry(Geometry,3857),
    insert_dt timestamp with time zone,
    update_dt timestamp with time zone,
    CONSTRAINT milestone_point_pkey PRIMARY KEY (gid)
);

ALTER TABLE hand.milestone_point OWNER to postgres;                                          

DROP TRIGGER IF EXISTS before_insert_dt ON hand.milestone_point;
DROP TRIGGER IF EXISTS before_update_dt ON hand.milestone_point;

CREATE TRIGGER before_insert_dt
before INSERT ON hand.milestone_point FOR EACH ROW
EXECUTE PROCEDURE hand.before_insert_dt();

CREATE TRIGGER before_update_dt
before UPDATE ON hand.milestone_point FOR EACH ROW
EXECUTE PROCEDURE hand.before_update_dt();

DO $$ 
    BEGIN
	RAISE INFO 'Построили таблицу Километровых столбов.';
    END;
$$;

DO $$ 
    BEGIN
	RAISE INFO 'Все таблицы успешно построены.';
    END;
$$;
