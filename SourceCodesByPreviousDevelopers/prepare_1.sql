--Удаление таблиц
CREATE SCHEMA IF NOT EXISTS osm AUTHORIZATION postgres;
DROP TABLE IF EXISTS osm.subway, osm.subway_point, osm.tram, osm.tram_stop, osm.trolleybus, osm.trolleybus_stop, osm.bus, osm.bus_stop, osm.taxi, osm.taxi_stop;
DROP TABLE IF EXISTS 
  osm.forts, osm.cemetery, osm.buildings, osm.settlements, osm.residential_complex, osm.water, osm.coast_line, 
  osm.water_line, osm.bridges, osm.regions, osm.parks, osm.reserve_parks,
  osm.square, osm.railway_platform, osm.industrial, osm.commercial, osm.commercial_point, osm.education, osm.education_point,
  osm.island, osm.landuse, osm.landuse_line,
  osm.route, osm.route_stop, osm.railway, osm.railway_point, osm.highways, osm.roads, osm.milestone_point,
  osm.barrier, osm.barrier_point, osm.power_line, osm.power_point, osm.entrance_point, osm.other_point;

DO $$
    BEGIN
	RAISE INFO 'Удалили таблицы.';
    END;
$$;
---------------------------

-- Строим таблицу Фортов osm.forts

DO $$
    BEGIN

CREATE TABLE osm.forts
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_housenumber text,
    addr_street text, street_id uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    building text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    hand text,
    geom geometry(MultiPolygon,3857),
    CONSTRAINT forts_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.forts OWNER to postgres;

insert into osm.forts (osm_id, addr_housenumber, addr_street, addr_city, building, name, geom) 
  (select osm_id, "addr:housenumber", "addr:street", "addr:city", building, name, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
    from public.planet_osm_polygon 
    where "addr:housenumber" is null and (name ilike '% форт' or name ilike 'форт %')
  );

delete from public.planet_osm_polygon where "addr:housenumber" is null and  (name ilike '% форт' or name ilike 'форт %');

    END;
$$;

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу фортов.';
    END;
$$;
---------------------------

-- Строим таблицу Кладбищ osm.cemetery

DO $$
    BEGIN

CREATE TABLE osm.cemetery
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_housenumber text,
    addr_street text, street_id uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    geom geometry(MultiPolygon,3857),
    CONSTRAINT cemetery_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.cemetery OWNER to postgres;

insert into osm.cemetery (osm_id, addr_housenumber, addr_street, addr_city, name, geom)
(
select p.osm_id, p."addr:housenumber", p."addr:street", p."addr:city", p.name,
       case when ST_IsValid(ST_CollectionExtract(p.way,3)) then ST_Multi(ST_CollectionExtract(p.way,3)) else null end
  from
  (
    select osm_id, "addr:housenumber", "addr:street", "addr:city", name, ST_Collect(way) as way
    from public.planet_osm_polygon where landuse ilike 'cemetery' or  name ilike '%кладбище%'
    group by osm_id, "addr:housenumber", "addr:street", "addr:city", name
  ) as p
);

delete from public.planet_osm_polygon where landuse ilike 'cemetery' or  name ilike '%кладбище%';

    END;
$$;

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу кладбищ.';
    END;
$$;

-- Строим таблицу Строений (домов) osm.buildings

DO $$
    BEGIN

CREATE TABLE osm.coast_line
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    area text,
    bay text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    ref text,
    geom geometry(MultiLineString,3857),
    CONSTRAINT coast_line_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.coast_line OWNER to postgres;

insert into osm.coast_line (osm_id, addr_city, area, bay, name, ref, geom)
( select osm_id, "addr:city", area, bay, name, ref, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_line where "natural"='coastline');
delete from public.planet_osm_line where "natural"='coastline';

    END;
$$;

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу береговой линии.';
    END;
$$;

-- Строим таблицу Строений (домов) osm.buildings

DO $$
    BEGIN

CREATE TABLE osm.buildings
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_flats text,
    addr_housenumber text,
    addr_housenumber_orig text,
    addr_street text, street_id uuid,
    addr_street_orig text,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    building text,
    construction text,
    disused text,
    historic text,
    landuse text,
    layer text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    hand text,
    operator text,
    ref text,
    religion text,
    service text,
    shop text,
    sport text,
    tourism text,
    geom geometry(MultiPolygon,3857),
    geonim_name text,
    geonim_type text,
    house_number text,
    house_korpus text,
    house_litera text,
    house_stroenie text,
    house_road_link text,
    CONSTRAINT buildings_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.buildings OWNER to postgres;

DROP INDEX IF EXISTS osm.addr_housenumber_buildings, osm.addr_street_buildings, osm.addr_city_buildings, osm.addr_district_buildings, osm.addr_reg_buildings, osm.name_buildings, osm.geonim_name_buildings, osm.geonim_type_buildings;

DROP INDEX IF EXISTS osm.geom_buildings;
CREATE INDEX geom_buildings ON osm.buildings USING GIST ( geom );


CREATE INDEX addr_housenumber_buildings ON osm.buildings USING HASH (addr_housenumber);
CREATE INDEX addr_street_buildings ON osm.buildings USING HASH (addr_street);
CREATE INDEX addr_city_buildings ON osm.buildings USING HASH (addr_city);
CREATE INDEX addr_district_buildings ON osm.buildings USING HASH (addr_district);
CREATE INDEX addr_reg_buildings ON osm.buildings USING HASH (addr_reg);
CREATE INDEX name_buildings ON osm.buildings USING HASH (name);
CREATE INDEX geonim_name_buildings ON osm.buildings USING HASH (geonim_name);
CREATE INDEX geonim_type_buildings ON osm.buildings USING HASH (geonim_type);

insert into osm.buildings (osm_id, addr_flats, addr_housenumber, addr_street, addr_city, building, construction, disused, historic, landuse, layer, name, operator, ref, religion, service, shop, sport, tourism, geom)

( select osm_id, "addr:flats",  "addr:housenumber", "addr:street", "addr:city", building,
         construction, disused, historic, landuse, layer, name, operator, ref, religion,
         service, shop, sport, tourism, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_polygon where building is not null);
delete from public.planet_osm_polygon where building is not null;

    END;
$$;

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу Строений (домов).';
    END;
$$;


-- Строим таблицу Населенных пунктов
CREATE TABLE osm.settlements
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    aoguid uuid,
    addr_city text, city_id uuid,
    addr_city_full text,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    admin_level smallint,
    boundary text,
    landuse text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    hand text,
    fullname text[],
    fullname_ru text,
    fullpath uuid[],
    place text,
    ref text,
    geonim_name text,
    geonim_type text,
    geom geometry(MultiPolygon,3857),
    geom_uniq geometry(MultiPolygon,3857),
    fromline boolean,
    updated boolean,
    CONSTRAINT settlements_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.settlements OWNER to postgres;

DROP INDEX IF EXISTS osm.addr_city_settlements, osm.addr_city_full_settlements, osm.addr_district_settlements, osm.addr_reg_settlements, osm.name_settlements, osm.fullname_settlements, osm.fullpath_settlements, osm.place_settlements, osm.geonim_name_settlements, osm.geonim_type_settlements;

DROP INDEX IF EXISTS osm.geom_settlements, osm.geom_uniq_settlements;
CREATE INDEX geom_settlements ON osm.settlements USING GIST ( geom );
CREATE INDEX geom_uniq_settlements ON osm.settlements USING GIST ( geom_uniq );

CREATE INDEX addr_city_settlements ON osm.settlements USING HASH (addr_city);
CREATE INDEX addr_city_full_settlements ON osm.settlements USING HASH (addr_city_full);
CREATE INDEX addr_district_settlements ON osm.settlements USING HASH (addr_district);
CREATE INDEX addr_reg_settlements ON osm.settlements USING HASH (addr_reg);
CREATE INDEX name_settlements ON osm.settlements USING HASH (name);
CREATE INDEX fullname_settlements ON osm.settlements USING HASH (fullname);
CREATE INDEX fullpath_settlements ON osm.settlements USING HASH (fullpath);
CREATE INDEX place_settlements ON osm.settlements USING HASH (place);
CREATE INDEX geonim_name_settlements ON osm.settlements USING HASH (geonim_name);
CREATE INDEX geonim_type_settlements ON osm.settlements USING HASH (geonim_type);

insert into osm.settlements (osm_id, addr_city, admin_level, boundary, landuse, name, place, ref, geom, geom_uniq, fromline)

(
  with bt as (
    select osm_id, "addr:city" as acity, CAST(nullif(admin_level, '') AS smallint) as admin_level, boundary, landuse, name, place, ref, ST_Collect(way) as way
    from public.planet_osm_polygon
    where ((place ='neighbourhood' and (landuse not in ('construction' ) or landuse is null) and (leisure <> 'park' or leisure is null))
    or place  in ('suburb', 'allotments', 'hamlet', 'village', 'town', 'city'))
    and name is not null and (landuse <> 'military' or landuse is null)
    group by osm_id, "addr:city", admin_level, boundary, landuse, name, place, ref
  ),
  p as (
    select *,
         case when ST_IsValid(ST_Multi(ST_CollectionExtract(bt.way,3))) then ST_Multi(ST_CollectionExtract(bt.way,3)) else null end as cway
      from bt

  )
    select p.osm_id, p.acity, p.admin_level, p.boundary, p.landuse, p.name, p.place, p.ref, cway, cway as uniq_way,false
   from p
);

-- таблица жилых комплексов
CREATE TABLE osm.residential_complex
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    aoguid uuid,
    addr_city text, city_id uuid,
    addr_city_full text,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    admin_level smallint,
    boundary text,
    landuse text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    hand text,
    fullname text[],
    fullname_ru text,
    fullpath uuid[],
    place text,
    ref text,
    geonim_name text,
    geonim_type text,
    geom geometry(MultiPolygon,3857),
    geom_uniq geometry(MultiPolygon,3857),
    fromline boolean,
    updated boolean,
    CONSTRAINT residential_complex_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.residential_complex OWNER to postgres;

DROP INDEX IF EXISTS osm.addr_city_residential_complex, osm.addr_city_full_residential_complex, osm.addr_district_residential_complex,
    osm.addr_reg_residential_complex, osm.name_residential_complex, osm.fullname_residential_complex, osm.fullpath_residential_complex,
    osm.place_residential_complex, osm.geonim_name_residential_complex, osm.geonim_type_residential_complex;

DROP INDEX IF EXISTS osm.geom_residential_complex, osm.geom_uniq_residential_complex;
CREATE INDEX geom_residential_complex ON osm.residential_complex USING GIST ( geom );
CREATE INDEX geom_uniq_residential_complex ON osm.residential_complex USING GIST ( geom_uniq );

CREATE INDEX addr_city_residential_complex ON osm.residential_complex USING HASH (addr_city);
CREATE INDEX addr_city_full_residential_complex ON osm.residential_complex USING HASH (addr_city_full);
CREATE INDEX addr_district_residential_complex ON osm.residential_complex USING HASH (addr_district);
CREATE INDEX addr_reg_residential_complex ON osm.residential_complex USING HASH (addr_reg);
CREATE INDEX name_residential_complex ON osm.residential_complex USING HASH (name);
CREATE INDEX fullname_residential_complex ON osm.residential_complex USING HASH (fullname);
CREATE INDEX fullpath_residential_complex ON osm.residential_complex USING HASH (fullpath);
CREATE INDEX place_residential_complex ON osm.residential_complex USING HASH (place);
CREATE INDEX geonim_name_residential_complex ON osm.residential_complex USING HASH (geonim_name);
CREATE INDEX geonim_type_residential_complex ON osm.residential_complex USING HASH (geonim_type);

insert into osm.residential_complex
    select * from osm.settlements where geonim('settlement','type', name) = 'жк';
delete from osm.settlements where geonim('settlement','type', name) = 'жк';

delete from public.planet_osm_polygon
  where ((place ='neighbourhood' and (landuse not in ('construction' ) or landuse is null) and (leisure <> 'park' or leisure is null))
  or place  in ('suburb', 'allotments', 'hamlet', 'village', 'town', 'city'))
  and name is not null and (landuse <> 'military' or  landuse is null);

insert into osm.settlements (osm_id, addr_city, admin_level, boundary, landuse, name, place, ref, geom, geom_uniq, fromline)
(
  with bt as (
    select osm_id, "addr:city" as acity, CAST(nullif(admin_level, '') AS smallint) as admin_level, boundary, landuse, name, place, ref, ST_Collect(way) as way
    from public.planet_osm_polygon
    where landuse = 'allotments' and name is not null
    group by osm_id, "addr:city", admin_level, boundary, landuse, name, place, ref
  ),
  p as (
    select *,
         case when ST_IsValid(ST_Multi(ST_CollectionExtract(bt.way,3))) then ST_Multi(ST_CollectionExtract(bt.way,3)) else null end as cway
      from bt

  )
    select  p.osm_id, p.acity, p.admin_level, p.boundary, p.landuse, p.name, p.place, p.ref,cway,cway as uniq_way, false
   from p
);
delete from public.planet_osm_polygon
where landuse = 'allotments' and name is not null;

insert into osm.settlements (osm_id, addr_city, admin_level, boundary, landuse, name, place, ref, geom, geom_uniq, fromline)
( with sid as (select distinct osm_id from osm.settlements)
  select  osm_id, "addr:city", CAST(nullif(admin_level, '') AS smallint), boundary, landuse, name, place, ref,
         case when ST_IsValid(ST_Multi(ST_MakePolygon(way))) then ST_Multi(ST_MakePolygon(way)) else null end,
         case when ST_IsValid(ST_Multi(ST_MakePolygon(way))) then ST_Multi(ST_MakePolygon(way)) else null end, true
  from public.planet_osm_line
  where osm_id not in (select osm_id from sid) and "place" in ('allotments','hamlet','locality','neighbourhood','suburb','village') and name not ilike('%жилой комплекс%') and ST_IsClosed(way) /* ST_EndPoint(way) = ST_StartPoint(way)*/ and ST_NPoints (way) > 3
);
delete  from public.planet_osm_line
  where "place" in ('allotments','hamlet','locality','neighbourhood','suburb','village') and name not ilike('%жилой комплекс%') and ST_IsClosed(way)/*ST_EndPoint(way) = ST_StartPoint(way)*/ and ST_NPoints (way) > 3;

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу Населенных пунктов.';
    END;
$$;

-- Строим таблицу Районов, округов

CREATE TABLE osm.regions
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    aoguid uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    admin_level smallint,
    boundary text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    hand text,
    ref text,
    geonim_name text,
    geonim_type text,
    updated boolean,
    geom geometry(MultiPolygon,3857),
    geom_uniq geometry(MultiPolygon,3857),
    CONSTRAINT regions_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.regions OWNER to postgres;

DROP INDEX IF EXISTS osm.addr_city_regions,osm.addr_district_regions,osm.addr_reg_regions,osm.name_regions,osm.geonim_name_regions,osm.geonim_type_regions;

DROP INDEX IF EXISTS osm.geom_regions, osm.geom_uniq_regions;
CREATE INDEX geom_regions ON osm.regions USING GIST ( geom );
CREATE INDEX geom_uniq_regions ON osm.regions USING GIST ( geom_uniq );

CREATE INDEX addr_city_regions ON osm.regions USING HASH (addr_city);
CREATE INDEX addr_district_regions ON osm.regions USING HASH (addr_district);
CREATE INDEX addr_reg_regions ON osm.regions USING HASH (addr_reg);
CREATE INDEX name_regions ON osm.regions USING HASH (name);
CREATE INDEX geonim_name_regions ON osm.regions USING HASH (geonim_name);
CREATE INDEX geonim_type_regions ON osm.regions USING HASH (geonim_type);

insert into osm.regions (osm_id, addr_city, admin_level, boundary, name, ref, geom, geom_uniq)
(
  with bt as (
    select osm_id, "addr:city" as acity, CAST(nullif(admin_level, '') AS smallint) as admin_level, boundary, name, ref, ST_Collect(way) as way
    from public.planet_osm_polygon
    where boundary = 'administrative'
    group by osm_id, "addr:city", admin_level, boundary, name, ref
  ),
  p as (
    select *,
         case when ST_IsValid(ST_Multi(ST_CollectionExtract(bt.way,3))) then ST_Multi(ST_CollectionExtract(bt.way,3)) else null end as cway
      from bt
  )
  select p.osm_id, p.acity, p.admin_level, p.boundary, p.name, p.ref, p.cway as geom, p.cway as geom_uniq
  from p
  where p.name is not null
);
delete from public.planet_osm_polygon where boundary = 'administrative';

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу Районов, округов.';
    END;
$$;


-- Строим таблицы Воды

CREATE TABLE osm.water
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    landuse text,
    layer text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    hand text,
    ref text,
    geom geometry(MultiPolygon,3857),
    CONSTRAINT water_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.water OWNER to postgres;

DROP INDEX IF EXISTS osm.addr_city_water,osm.addr_district_water,osm.addr_reg_water,osm.name_water;

DROP INDEX IF EXISTS osm.geom_water;
CREATE INDEX geom_water ON osm.water USING GIST ( geom );

CREATE INDEX addr_city_water ON osm.water USING HASH (addr_city);
CREATE INDEX addr_district_water ON osm.water USING HASH (addr_district);
CREATE INDEX addr_reg_water ON osm.water USING HASH (addr_reg);
CREATE INDEX name_water ON osm.water USING HASH (name);


insert into osm.water (osm_id, addr_city, landuse, layer, name, ref, geom)

( select osm_id, "addr:city", landuse, layer, name, ref, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_polygon
  where (waterway is not null or "natural" in ('water', 'bay')) or place = 'sea'
);
delete from public.planet_osm_polygon where (waterway is not null or "natural" in ('water', 'bay')) or place = 'sea';


CREATE TABLE osm.water_line
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    landuse text,
    layer text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    ref text,
    waterway text,
    geom geometry(MultiLineString,3857),
    CONSTRAINT water_line_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.water_line OWNER to postgres;

DROP INDEX IF EXISTS osm.addr_city_water_line,osm.addr_district_water_line,osm.addr_reg_water_line,osm.name_water_line;

DROP INDEX IF EXISTS osm.geom_water_line;
CREATE INDEX geom_water_line ON osm.water_line USING GIST ( geom );

CREATE INDEX addr_city_water_line ON osm.water_line USING HASH (addr_city);
CREATE INDEX addr_district_water_line ON osm.water_line USING HASH (addr_district);
CREATE INDEX addr_reg_water_line ON osm.water_line USING HASH (addr_reg);
CREATE INDEX name_water_line ON osm.water_line USING HASH (name);

insert into osm.water_line (osm_id, addr_city, landuse, layer, name, ref, waterway, geom)
( select osm_id, "addr:city", landuse, layer, name, ref, waterway, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_line
  where waterway is not null or "natural" in ('water', 'bay')
);
 delete from public.planet_osm_line where waterway is not null or  "natural" in ('water', 'bay');

DO $$
    BEGIN
	RAISE INFO 'Построили таблицы Воды.';
    END;
$$;

-- Строим таблицу Мостов, виадуков

CREATE TABLE osm.bridges
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_street text, street_id uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    highway text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    ref text,
    geom geometry(MultiPolygon,3857),
    CONSTRAINT bridges_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.bridges OWNER to postgres;

insert into osm.bridges (osm_id, addr_street, addr_city, highway, name, ref, geom)
( select osm_id, "addr:street", "addr:city", highway, name, ref, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_polygon
  where man_made='bridge'
);
delete from public.planet_osm_polygon where man_made='bridge';

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу Мостов, виадуков.';
    END;
$$;
---------------------------

-- Строим таблицу Парков

CREATE TABLE osm.parks
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_street text, street_id uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    boundary text,
    landuse text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    hand text,
    place text,
    ref text,
    geom geometry(MultiPolygon,3857),
    CONSTRAINT parks_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.parks OWNER to postgres;

insert into osm.parks (osm_id, addr_street, addr_city, boundary, landuse, name, place, ref, geom)
(
  with bt as (
    select osm_id, "addr:street" as astreet, "addr:city" as acity, boundary, landuse, name, place, ref, ST_Collect(way) as way
  from public.planet_osm_polygon
  where (landuse = 'park' or leisure= 'park' ) and name is not null
  group by osm_id, "addr:street", "addr:city", admin_level, boundary, landuse, name, place, ref
  )
  select osm_id, astreet, acity, boundary, landuse, name, place, ref,
       case when ST_IsValid(ST_Multi(ST_CollectionExtract(bt.way,3))) then ST_Multi(ST_CollectionExtract(bt.way,3)) else null end as cway
  from bt
);
delete from public.planet_osm_polygon where (landuse = 'park' or leisure= 'park' ) and name is not null;

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу Парков.';
    END;
$$;

-- Строим таблицу Заказников

CREATE TABLE osm.reserve_parks
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_street text, street_id uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    boundary text,
    landuse text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    place text,
    ref text,
    geom geometry(MultiPolygon,3857),
    CONSTRAINT reserve_parks_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.reserve_parks OWNER to postgres;

insert into osm.reserve_parks (osm_id, addr_street, addr_city, boundary, landuse, name, place, ref, geom)
(
  select osm_id, "addr:street", "addr:city", boundary, landuse, name, place, ref,
       case when ST_IsValid(ST_CollectionExtract(p.way,3)) then ST_Multi(ST_CollectionExtract(p.way,3)) else null end as way
  from
  (
    select osm_id, "addr:street", "addr:city", boundary, landuse, name, place, ref, ST_Collect(way) as way
    from public.planet_osm_polygon
    where (landuse = 'natural_reserve' or leisure= 'nature_reserve' ) and name is not null
    group by osm_id, "addr:street", "addr:city", admin_level, boundary, landuse, name, place, ref
  ) as p
);
delete from public.planet_osm_polygon where (landuse = 'natural_reserve' or leisure= 'nature_reserve' ) and name is not null;

insert into osm.reserve_parks (osm_id, addr_street, addr_city, boundary, landuse, name, place, ref, geom)
(
  select  osm_id, "addr:street", "addr:city", boundary, landuse, name, place, ref,
    case when ST_IsValid(ST_CollectionExtract(p.way,3)) then ST_Multi(ST_CollectionExtract(p.way,3)) else null end as way
  from
  (
    select  osm_id, "addr:street", "addr:city", boundary, landuse, name, place, ref,
          case when ST_IsValid(ST_Collect(ST_MakePolygon(way))) then ST_Collect(ST_MakePolygon(way)) else null end as way
    from public.planet_osm_line
    where "boundary" is not null and (name ilike '%заказник%' or name ilike '%исторический%' or name ilike '%парк%' ) and ST_IsClosed(way) /*ST_EndPoint(way) = ST_StartPoint(way)*/ and ST_NPoints (way) > 3
    group by osm_id, "addr:street", "addr:city", boundary, landuse, name, place, ref
  ) as p
);
 delete from public.planet_osm_line where "boundary" is not null;

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу Заказников.';
    END;
$$;

-- Строим таблицу Площадей

CREATE TABLE osm.square
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_street text, street_id uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    hand text,
    ref text,
    geom geometry(MultiPolygon,3857),
    CONSTRAINT square_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.square OWNER to postgres;

insert into osm.square (osm_id, addr_street, addr_city, name, ref, geom)
(
  select osm_id, "addr:street", "addr:city", name, ref, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_polygon
  where "place" ='square'
);
delete from public.planet_osm_polygon where "place" ='square';

insert into osm.square (osm_id, addr_street, addr_city, name, ref, geom)
(
  select osm_id, "addr:street", "addr:city", name, ref,
    case when ST_IsValid(ST_CollectionExtract(p.way,3)) then ST_Multi(ST_CollectionExtract(p.way,3)) else null end as way
  from
  (
  select osm_id, "addr:street", "addr:city", name, ref,
   case when ST_IsValid(ST_Collect(ST_MakePolygon(way))) then ST_Collect(ST_MakePolygon(way)) else null end as way
  from public.planet_osm_line
  where "place" ='square' and ST_IsClosed(way) /*ST_EndPoint(way) = ST_StartPoint(way)*/ and ST_NPoints (way) > 3
  group by osm_id, "addr:street", "addr:city", admin_level, boundary, landuse, name, place, ref
  ) as p
);
 delete from public.planet_osm_line where "place" ='square';

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу Площадей.';
    END;
$$;

-- Строим таблицу Ж/Д платформ

CREATE TABLE osm.railway_platform
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_street text, street_id uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    layer text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    operator text,
    ref text,
    geom geometry(MultiPolygon,3857),
    CONSTRAINT railway_platform_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.railway_platform OWNER to postgres;

insert into osm.railway_platform (osm_id, addr_street, addr_city, layer, name, operator, ref, geom)
( select osm_id, "addr:street", "addr:city", layer, name, operator, ref, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_polygon where railway = 'platform'
);
delete from public.planet_osm_polygon where railway = 'platform';

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу Ж/Д платформ.';
    END;
$$;
---------------------------

-- Строим таблицу Производств

CREATE TABLE osm.industrial
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_housenumber text,
    addr_street text, street_id uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    operator text,
    ref text,
    geom geometry(MultiPolygon,3857),
    CONSTRAINT industrial_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.industrial OWNER to postgres;

insert into osm.industrial (osm_id, addr_housenumber, addr_street, addr_city, name, operator, ref, geom)
( select osm_id, "addr:housenumber", "addr:street", "addr:city", name, operator, ref, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_polygon where landuse = 'industrial'
);
delete from public.planet_osm_polygon where landuse = 'industrial';

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу Производств.';
    END;
$$;

-- Строим таблицу Бизнеса

CREATE TABLE osm.commercial
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_housenumber text,
    addr_street text, street_id uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    operator text,
    ref text,
    service text,
    shop text,
    tourism text,
    geom geometry(MultiPolygon,3857),
    CONSTRAINT commercial_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.commercial OWNER to postgres;

insert into osm.commercial (osm_id, addr_housenumber, addr_street, addr_city, name, operator, ref, service, shop, tourism, geom)
( select osm_id, "addr:housenumber", "addr:street", "addr:city", name, operator, ref, service, shop, tourism, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_polygon where landuse = 'commercial'
);
delete from public.planet_osm_polygon where landuse = 'commercial';

-- Строим таблицу Точек Бизнеса

CREATE TABLE osm.commercial_point
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_housenumber text,
    addr_street text, street_id uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    operator text,
    ref text,
    religion text,
    service text,
    shop text,
    sport text,
    tourism text,
    geom geometry(MultiPoint,3857),
    CONSTRAINT commercial_point_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.commercial_point OWNER to postgres;

insert into osm.commercial_point (osm_id, addr_housenumber, addr_street, addr_city,  name, operator, ref, religion, service, shop, sport, tourism, geom)
( select osm_id, "addr:housenumber", "addr:street", "addr:city", name, operator, ref, religion, service, shop, sport, tourism, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_point where shop is not null
);
delete from public.planet_osm_point where shop is not null;

insert into osm.commercial_point (osm_id, addr_housenumber, addr_street, addr_city,  name, operator, ref, religion, service, shop, sport, tourism, geom)
( select  osm_id, "addr:housenumber", "addr:street", "addr:city", name, operator, ref, religion, service, shop, sport, tourism, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_point
  where "amenity" in ('atm', 'atm;payment_terminal', 'bank', 'bar','bbq','beauty salon','boat_rental','business_centre','cafe','car_rental','car_wash','casino','club','credit','credit_union','fast_food','food_court','fuel','ice_cream''internet_cafe','marketplace','money_lender','money_transfer','nightclub','office','offices','parking','parking_entrance','parking_space','payment_terminal','pharmacy','photo_booth','pub','public_bath','sexshop','shower','soccer_club','spa','stripclub')
);
delete from public.planet_osm_point where "amenity" in ('atm', 'atm;payment_terminal', 'bank', 'bar','bbq','beauty salon','boat_rental','business_centre','cafe','car_rental','car_wash','casino','club','credit','credit_union','fast_food','food_court','fuel','ice_cream''internet_cafe','marketplace','money_lender','money_transfer','nightclub','office','offices','parking','parking_entrance','parking_space','payment_terminal','pharmacy','photo_booth','pub','public_bath','sexshop','shower','soccer_club','spa','stripclub');

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу Бизнеса.';
    END;
$$;

-- Строим таблицу Учебных заведений

CREATE TABLE osm.education
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_housenumber text,
    addr_street text, street_id uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    construction text,
    disused text,
    landuse text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    operator text,
    ref text,
    religion text,
    tourism text,
    geom geometry(MultiPolygon,3857),
    CONSTRAINT education_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.education OWNER to postgres;

insert into osm.education (osm_id, addr_housenumber, addr_street, addr_city, construction, disused, landuse, name, operator, ref, religion, tourism, geom)
( select osm_id,  "addr:housenumber", "addr:street", "addr:city", construction, disused, landuse, name, operator, ref, religion, tourism, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_polygon
  where amenity in ('college','kindergarten','library','archive','public_bookcase','school','music_school','driving_school','language_school','university','research_institute')
);
delete from public.planet_osm_polygon where amenity in ('college','kindergarten','library','archive','public_bookcase','school','music_school','driving_school','language_school','university','research_institute');


CREATE TABLE osm.education_point
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_housenumber text,
    addr_street text, street_id uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    operator text,
    ref text,
    religion text,
    tourism text,
    geom geometry(MultiPoint,3857),
    CONSTRAINT education_point_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.education_point OWNER to postgres;

insert into osm.education_point (osm_id, addr_housenumber, addr_street, addr_city, name, operator, ref, religion, tourism, geom)
( select  osm_id, "addr:housenumber", "addr:street", "addr:city", name, operator, ref, religion, tourism, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_point
  where amenity in ('college','kindergarten','library','archive','public_bookcase','school','music_school','driving_school','language_school','university','research_institute')
);
delete from public.planet_osm_point where amenity in ('college','kindergarten','library','archive','public_bookcase','school','music_school','driving_school','language_school','university','research_institute');

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу Учебных заведений.';
    END;
$$;

-- Строим таблицу Островов

CREATE TABLE osm.island
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    hand text,
    place text,
    ref text,
    geom geometry(MultiPolygon,3857),
    CONSTRAINT island_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.island OWNER to postgres;

insert into osm.island (osm_id, addr_city, name, place, ref, geom)
( select osm_id, "addr:city", name, place, ref, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_polygon where place in ('island', 'islet')
);
delete from public.planet_osm_polygon where place in ('island', 'islet');

insert into osm.island (osm_id, addr_city, name, place, ref, geom)
( with sid as (select distinct osm_id from osm.island)
  select osm_id, "addr:city", name, place, ref, case when ST_IsValid(ST_Multi(ST_MakePolygon(way))) then ST_Multi(ST_MakePolygon(way)) else null end
  from public.planet_osm_line
  where osm_id not in (select osm_id from sid) and "place" in ('island','islet') and name is not null and ST_IsClosed(way) /*ST_EndPoint(way) = ST_StartPoint(way)*/ and ST_NPoints (way) > 3
);
 delete from public.planet_osm_line where "place" in ('island','islet');

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу Островов.';
    END;
$$;

-- Строим таблицу Землепользования

CREATE TABLE osm.landuse
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_housenumber text,
    addr_street text, street_id uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    boundary text,
    construction text,
    disused text,
    highway text,
    historic text,
    landuse text,
    layer text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    land_surface text,
    operator text,
    place text,
    ref text,
    religion text,
    service text,
    shop text,
    sport text,
    tourism text,
    geom geometry(MultiPolygon,3857),
    CONSTRAINT landuse_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.landuse OWNER to postgres;

insert into osm.landuse (osm_id, addr_housenumber, addr_street, addr_city, boundary, construction, disused, highway, historic, landuse, layer, name, land_surface, operator, place, ref, religion, service, shop, sport, tourism, geom)
( select osm_id, "addr:housenumber", "addr:street", "addr:city", boundary, construction, disused, highway, historic, landuse, layer, name, "natural", operator, place, ref, religion, service, shop, sport, tourism, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_polygon
);
delete from public.planet_osm_polygon where true;

insert into osm.landuse (osm_id, addr_housenumber, addr_street, addr_city, boundary, construction, disused, highway, historic, landuse, layer, name, operator, place, ref, religion, service, shop, sport, tourism, geom)
( with sid as (select distinct osm_id from osm.landuse)
  select osm_id, "addr:housenumber", "addr:street", "addr:city", boundary, construction, disused, highway, historic, landuse, layer, name, operator, place, ref, religion, service, shop, sport, tourism,
     case when ST_IsValid(ST_Multi(ST_MakePolygon(way))) then ST_Multi(ST_MakePolygon(way)) else null end
  from public.planet_osm_line
  where osm_id not in (select osm_id from sid) and ST_IsClosed(way) /*ST_EndPoint(way) = ST_StartPoint(way)*/ and ST_NPoints (way) > 3 and "natural" is null and "man_made" is null
);
  delete from public.planet_osm_line where ST_IsClosed(way) /*ST_EndPoint(way) = ST_StartPoint(way)*/ and ST_NPoints (way) > 3 and "natural" is null and "man_made" is null;

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу Землепользования.';
    END;
$$;

-- Строим таблицу Линий землепользования

CREATE TABLE osm.landuse_line
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_housenumber text,
    addr_street text, street_id uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    boundary text,
    construction text,
    disused text,
    highway text,
    historic text,
    landuse text,
    layer text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    operator text,
    place text,
    ref text,
    religion text,
    service text,
    shop text,
    sport text,
    tourism text,
    geom geometry(MultiLineString,3857),
    CONSTRAINT landuse_line_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.landuse_line OWNER to postgres;

insert into osm.landuse_line (osm_id, addr_housenumber, addr_street, addr_city, boundary, construction, disused, highway, historic, landuse, layer, name, operator, place, ref, religion, service, shop, sport, tourism, geom)
( select osm_id, "addr:housenumber", "addr:street", "addr:city", boundary, construction, disused, highway, historic, landuse, layer, name, operator, place, ref, religion, service, shop, sport, tourism, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_line
  where "natural" in ( 'tree',  'tree_row' , 'wood')
);
 delete from public.planet_osm_line where "natural" in ( 'tree',  'tree_row' , 'wood');

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу Линий землепользования.';
    END;
$$;

-- Строим таблицу маршрутов

CREATE TABLE osm.route
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    route_type text,
	addr_street text, street_id uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    construction text,
    disused text,
    highway text,
    historic text,
    layer text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    operator text,
    ref text,
    service text,
    geom geometry(MultiLineString,3857),
    CONSTRAINT route_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.route OWNER to postgres;

--Строим таблицу Метро

insert into osm.route(osm_id, route_type, addr_city, construction, disused, layer, name, operator, ref, geom)
(select osm_id, 'subway', "addr:city", construction, disused, layer, name, operator, ref, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
    from public.planet_osm_roads
    where railway = 'subway' or construction = 'subway' or disused = 'subway');
delete from public.planet_osm_roads where railway = 'subway' or construction = 'subway' or disused = 'subway';

insert into osm.route(osm_id, route_type, addr_city, construction, disused, layer, name, operator, ref, geom)
(select osm_id, 'subway', "addr:city", construction, disused, layer, name, operator, ref, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
    from public.planet_osm_roads
    where railway is not null and tunnel = 'yes');
delete from public.planet_osm_roads where railway is not null and tunnel = 'yes';

insert into osm.route(osm_id, route_type, addr_city, construction, disused, layer, name, operator, ref, geom)
(with sid as(select distinct osm_id from osm.route)
    select osm_id, 'subway', "addr:city", construction, disused, layer, name, operator, ref, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
    from public.planet_osm_line
    where osm_id not in(select osm_id from sid)and route = 'subway');
delete from public.planet_osm_line where route = 'subway';

--Строим таблицу Трамваев
insert into osm.route(osm_id, route_type, addr_street, addr_city, construction, disused, highway, historic, name, operator, ref, service, geom)
(select osm_id, 'tram', "addr:street", "addr:city", construction, disused, highway, historic, name, operator, ref, service, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
    from public.planet_osm_roads
    where railway = 'tram' or construction = 'tram' or disused = 'tram');
delete from public.planet_osm_roads where railway = 'tram' or construction = 'tram' or disused = 'tram';

insert into osm.route(osm_id, route_type, addr_street, addr_city, construction, disused, highway, historic, name, operator, ref, service, geom)
(with sid as(select distinct osm_id from osm.route)
    select osm_id, 'tram', "addr:street", "addr:city", construction, disused, highway, historic, name, operator, ref, service, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
    from public.planet_osm_line
    where osm_id not in(select osm_id from sid)and route in('tram', 'tram_cancelled', 'tram_temporary_cancelled'));
delete from public.planet_osm_line where route in('tram', 'tram_cancelled', 'tram_temporary_cancelled');

--Строим таблицу Тролейбусов
insert into osm.route(osm_id, route_type, addr_street, addr_city, construction, disused, highway, historic, name, operator, ref, service, geom)
(select osm_id, 'trolleybus', "addr:street", "addr:city", construction, disused, highway, historic, name, operator, ref, service, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
    from public.planet_osm_line
    where route = 'trolleybus');
delete from public.planet_osm_line where route = 'trolleybus';

--Строим таблицу Автобусов
insert into osm.route(osm_id, route_type, addr_street, addr_city, construction, disused, highway, historic, name, operator, ref, service, geom)
(select osm_id, 'bus', "addr:street", "addr:city", construction, disused, highway, historic, name, operator, ref, service, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
    from public.planet_osm_line
    where route = 'bus');
delete from public.planet_osm_line where route = 'bus';

--Строим таблицу Такси
insert into osm.route(osm_id, route_type, addr_street, addr_city, construction, disused, highway, historic, name, operator, ref, service, geom)
(select osm_id, 'taxi', "addr:street", "addr:city", construction, disused, highway, historic, name, operator, ref, service, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
    from public.planet_osm_line
    where route = 'share_taxi');
delete from public.planet_osm_line where route = 'share_taxi';

--Строим остальные маршруты
insert into osm.route(osm_id, route_type, addr_street, addr_city, historic, name, operator, ref, geom)
(select osm_id, 'other', "addr:street", "addr:city", historic, name, operator, ref, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
    from public.planet_osm_line
    where route is not null);
delete from public.planet_osm_line where route is not null;

-- Строим таблицу остановок

CREATE TABLE osm.route_stop
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    route_type text,
    addr_housenumber text,
    addr_street text, street_id uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    construction text,
    disused text,
    highway text,
    historic text,
    layer text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    operator text,
    ref text,
    service text,
    geom geometry(MultiPoint,3857),
    CONSTRAINT route_stop_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.route_stop OWNER to postgres;

--Строим таблицу Станций Метро
insert into osm.route_stop(osm_id, route_type, addr_housenumber, addr_street, addr_city, layer, name, operator, ref, geom)
(select osm_id, 'subway', "addr:housenumber", "addr:street", "addr:city", layer, name, operator, ref, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
    from public.planet_osm_point
    where "railway" in('subway_entrance', 'subway_exit'));
delete from public.planet_osm_point where "railway" in('subway_entrance', 'subway_exit');
delete from public.planet_osm_point where operator ilike '%метро%';

--Строим таблицу Остановок Трамваев
insert into osm.route_stop(osm_id, route_type, addr_housenumber, addr_street, addr_city, construction, disused, highway, historic, name, operator, ref, service, geom)
(select osm_id, 'tram', "addr:housenumber", "addr:street", "addr:city", construction, disused, highway, historic, name, operator, ref, service, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
    from public.planet_osm_point
    where "railway" = 'tram_stop');
delete from public.planet_osm_point where "railway" = 'tram_stop';

--Строим таблицу Остановок Тролейбусов
insert into osm.route_stop(osm_id, route_type, addr_housenumber, addr_street, addr_city, construction, disused, highway, historic, name, operator, ref, service, geom)
(select osm_id, 'trolleybus', "addr:housenumber", "addr:street", "addr:city", construction, disused, highway, historic, name, operator, ref, service, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
    from public.planet_osm_point
    where highway = 'trolleybus_stop');
delete from public.planet_osm_point where highway = 'trolleybus_stop';

--Строим таблицу Остановок Автобусов
insert into osm.route_stop(osm_id, route_type, addr_housenumber, addr_street, addr_city, construction, disused, highway, historic, name, operator, ref, service, geom)
(select osm_id, 'bus', "addr:housenumber", "addr:street", "addr:city", construction, disused, highway, historic, name, operator, ref, service, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
    from public.planet_osm_point
    where highway = 'bus_stop' or amenity = 'bus_station');
delete from public.planet_osm_point where highway = 'bus_stop' or amenity = 'bus_station';

--Строим таблицу Остановок Такси
insert into osm.route_stop(osm_id, route_type, addr_housenumber, addr_street, addr_city, construction, disused, highway, historic, name, operator, ref, service, geom)
(select osm_id, 'taxi', "addr:housenumber", "addr:street", "addr:city", construction, disused, highway, historic, name, operator, ref, service, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
    from public.planet_osm_point
    where highway = 'share_taxi_stop' or amenity = 'taxi');
delete from public.planet_osm_point where highway = 'share_taxi_stop' or amenity = 'taxi';

--Строим таблицу остальных остановок
insert into osm.route_stop(osm_id, route_type, addr_housenumber, addr_street, addr_city, construction, disused, layer, name, operator, ref, geom)
(select osm_id, 'other', "addr:housenumber", "addr:street", "addr:city", construction, disused, layer, name, operator, ref, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
    from public.planet_osm_point
    where highway in('stop', 'no'));
delete from public.planet_osm_point where highway in('stop', 'no');

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу остановок.';
    END;
$$;

-- Строим таблицу ЖД

CREATE TABLE osm.railway
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    construction text,
    disused text,
    highway text,
    layer text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    operator text,
    ref text,
    service text,
    geom geometry(MultiLineString,3857),
    CONSTRAINT railway_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.railway OWNER to postgres;

insert into osm.railway (osm_id, addr_city, construction, disused, highway, layer, name, operator, ref, service, geom)
( select osm_id, "addr:city", construction, disused, highway, layer, name, operator, ref, service, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_roads
  where railway is not null
);
delete from public.planet_osm_roads where railway is not null;

insert into osm.railway (osm_id, addr_city, construction, disused, highway, layer, name, operator, ref, service, geom)
( with sid as (select distinct osm_id from osm.railway)
  select osm_id, "addr:city", construction, disused, highway, layer, name, operator, ref, service, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_line
  where osm_id not in (select osm_id from sid) and route in ('train', 'railway')
);
 delete from public.planet_osm_line where route in ('train', 'railway') ;

-- Строим таблицу ЖД и метро станций

CREATE TABLE osm.railway_point
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_housenumber text,
    addr_street text, street_id uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    layer text,
    railway text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    hand text,
    operator text,
    ref text,
    geom geometry(MultiPoint,3857),
    CONSTRAINT railway_point_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.railway_point OWNER to postgres;

insert into osm.railway_point (osm_id, addr_housenumber, addr_street, addr_city, layer, railway, name, operator, ref, geom)
( select osm_id, "addr:housenumber", "addr:street", "addr:city", layer, "railway", name, operator, ref, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_point
  where "railway" in ('station', 'stop', 'halt')
);
delete from public.planet_osm_point where "railway" in ('station', 'stop', 'halt');

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу ЖД.';
    END;
$$;

-- Удаляем из public.planet_osm_line все, что нашли (метро, ЖД, трамвай)
--!!! delete from public.planet_osm_line where osm_id in (select osm_id from osm.subway);
--!!! delete from public.planet_osm_line where osm_id in (select osm_id from osm.tram);
--!!! delete from public.planet_osm_line where osm_id in (select osm_id from osm.railway);

DO $$
    BEGIN
	RAISE INFO 'Удалили из public.planet_osm_line все, что нашли (метро, ЖД, трамвай).';
    END;
$$;

delete from public.planet_osm_roads where highway is null;

-- Строим таблицу Автомагистралей (ЗСД, КАД)

CREATE TABLE osm.highways
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    aoguid uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    construction text,
    highway text,
    bridge text,
    layer text,
    lanes text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    hand text,
    oneway text,
    operator text,
    ref text,
    route text,
    service text,
    surface text,
    maxspeed text,
    maxspeed_int integer,
    tunnel text,
    width text,
    geonim_name text,
    geonim_type text,
    geom geometry(MultiLineString,3857),
    CONSTRAINT highway_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.highways OWNER to postgres;

DROP INDEX IF EXISTS osm.addr_city_highways,osm.addr_district_highways,osm.addr_reg_highways,osm.name_highways,osm.geonim_name_highways,osm.geonim_type_highways;

DROP INDEX IF EXISTS osm.geom_highways;
CREATE INDEX geom_highways ON osm.highways USING GIST ( geom );

CREATE INDEX addr_city_highways ON osm.highways USING HASH (addr_city);
CREATE INDEX addr_district_highways ON osm.highways USING HASH (addr_district);
CREATE INDEX addr_reg_highways ON osm.highways USING HASH (addr_reg);
CREATE INDEX name_highways ON osm.highways USING HASH (name);
CREATE INDEX geonim_name_highways ON osm.highways USING HASH (geonim_name);
CREATE INDEX geonim_type_highways ON osm.highways USING HASH (geonim_type);

insert into osm.highways (osm_id, addr_city, construction, highway, bridge, layer, lanes, name, oneway, operator, ref, route, service, surface, maxspeed, tunnel, width, geom)
( select osm_id, "addr:city", construction, highway, bridge, layer, lanes, name, oneway, operator, ref, route, service, surface, maxspeed, tunnel, width, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_roads
  where (HIGHWAY = 'trunk' OR HIGHWAY = 'motorway') and (name ilike 'ЗСД' or name ilike  'КАД' or ref='М-11')
);
delete from public.planet_osm_roads where (HIGHWAY = 'trunk' OR HIGHWAY = 'motorway') and (name ilike 'ЗСД' or name ilike  'КАД' or ref='М-11');

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу Автомагистралей (ЗСД, КАД).';
    END;
$$;
---------------------------

-- Строим таблицу дорог

CREATE TABLE osm.roads
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    aoguid uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    construction text,
    highway text,
    bridge text,
    layer text,
    lanes text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    hand text,
    oneway text,
    operator text,
    ref text,
    route text,
    service text,
    surface text,
    maxspeed text,
    maxspeed_int integer,
    tunnel text,
    width text,
    geonim_name text,
    geonim_type text,
    geom geometry(MultiLineString,3857),
    CONSTRAINT roads_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.roads OWNER to postgres;

DROP INDEX IF EXISTS osm.addr_city_roads,osm.addr_district_roads,osm.addr_reg_roads,osm.name_roads,osm.geonim_name_roads,osm.geonim_type_roads;
DROP INDEX IF EXISTS osm.geom_roads;
CREATE INDEX geom_roads ON osm.roads USING GIST ( geom );

CREATE INDEX addr_city_roads ON osm.roads USING HASH (addr_city);
CREATE INDEX addr_district_roads ON osm.roads USING HASH (addr_district);
CREATE INDEX addr_reg_roads ON osm.roads USING HASH (addr_reg);
CREATE INDEX name_roads ON osm.roads USING HASH (name);
CREATE INDEX geonim_name_roads ON osm.roads USING HASH (geonim_name);
CREATE INDEX geonim_type_roads ON osm.roads USING HASH (geonim_type);


insert into osm.roads (osm_id, addr_city, construction, highway, bridge, layer, lanes, name, oneway, operator, ref, route, service, surface, maxspeed, tunnel, width, geom)
( select osm_id, "addr:city", construction, highway, bridge, layer, lanes, name, oneway, operator, ref, route, service, surface, maxspeed, tunnel, width, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_roads
  where highway is not null
);
delete from public.planet_osm_roads where highway is not null;

 delete from public.planet_osm_line where boundary = 'administrative';

insert into osm.roads (osm_id, addr_city, construction, highway, bridge, layer, lanes, name, oneway, operator, ref, route, service, surface, maxspeed, tunnel, width, geom)
( with rid as (select distinct osm_id from osm.roads
               union
               select distinct osm_id from osm.highways),
  sid as (select distinct osm_id from rid)
  select osm_id, "addr:city", construction, highway, bridge, layer, lanes, name, oneway, operator, ref, route, service, surface, maxspeed, tunnel, width, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_line
  where osm_id not in (select osm_id from sid) and highway is not null  and highway not in ('trunk', 'motorway')
);
 delete from public.planet_osm_line where highway is not null;

-- Строим таблицу Километровых столбов

CREATE TABLE osm.milestone_point
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_housenumber text,
    addr_street text, street_id uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    distance text,
    layer text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    hand text,
    ref text,
    geom geometry(MultiPoint,3857),
    CONSTRAINT milestone_point_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.milestone_point OWNER to postgres;

insert into osm.milestone_point (osm_id, addr_housenumber, addr_street, addr_city, distance, layer, name, ref, geom)
( select osm_id, "addr:housenumber", "addr:street", "addr:city", distance, layer, name, ref, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_point
  where highway ='milestone'
);
delete from public.planet_osm_point where highway ='milestone';

update osm.milestone_point oldmp set addr_street = mpn.name, addr_city = mpn.addr_city
from
(
  WITH rd AS (select addr_city, name, geom from osm.roads where name is not null),
  mlp AS (select * from osm.milestone_point where distance is not null)
  select distinct r.addr_city, mp.osm_id, mp.distance, r.name FROM mlp mp join
  rd r on ST_DWithin(mp.geom, r.geom, 50)
) mpn
where mpn.osm_id=oldmp.osm_id;

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу Километровых столбов.';
    END;
$$;

-- Строим таблицу заборов, стен и прочих препятствий

CREATE TABLE osm.barrier
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_housenumber text,
    addr_street text, street_id uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    landuse text,
    layer text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    operator text,
    ref text,
    tourism text,
    geom geometry(MultiLineString,3857),
    CONSTRAINT barrier_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.barrier OWNER to postgres;

insert into osm.barrier (osm_id, addr_housenumber, addr_street, addr_city, landuse, layer, name, ref, tourism, geom)
( select osm_id, "addr:housenumber", "addr:street", "addr:city", landuse, layer, name, ref, tourism, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_line
  where barrier is not null
);
 delete from public.planet_osm_line where barrier is not null;

-- Строим таблицу Электричества

CREATE TABLE osm.barrier_point
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_housenumber text,
    addr_street text, street_id uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    operator text,
    ref text,
    geom geometry(MultiPoint,3857),
    CONSTRAINT barrier_point_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.barrier_point OWNER to postgres;

insert into osm.barrier_point (osm_id, addr_housenumber, addr_street, addr_city, name, operator, ref, geom)
( select osm_id, "addr:housenumber", "addr:street", "addr:city", name, operator, ref, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_point
  where barrier is not null
);
delete from public.planet_osm_point where barrier is not null;

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу заборов, стен и прочих препятствий.';
    END;
$$;

-- Строим таблицу Электричества

CREATE TABLE osm.power_line
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    construction text,
    disused text,
    layer text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    operator text,
    ref text,
    geom geometry(MultiLineString,3857),
    CONSTRAINT power_line_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.power_line OWNER to postgres;

insert into osm.power_line (osm_id, addr_city, construction, disused, layer, name, operator, ref, geom)
( select osm_id, "addr:city", construction, disused, layer, name, operator, ref, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_line
  where "power" is not null
);
 delete from public.planet_osm_line where "power" is not null;

-- Строим таблицу Электричества

CREATE TABLE osm.power_point
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_housenumber text,
    addr_street text, street_id uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    building text,
    construction text,
    disused text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    operator text,
    ref text,
    geom geometry(MultiPoint,3857),
    CONSTRAINT power_point_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.power_point OWNER to postgres;

insert into osm.power_point (osm_id, addr_housenumber, addr_street, addr_city, building, construction, disused, name, operator, ref, geom)
( select osm_id, "addr:housenumber", "addr:street", "addr:city", building, construction, disused, name, operator, ref, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_point
  where "power" is not null
);
delete from public.planet_osm_point where "power" is not null;

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу Электричества.';
    END;
$$;

-- Строим таблицу Подъездов

CREATE TABLE osm.entrance_point
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_flats text,
    addr_housenumber text,
    addr_street text, street_id uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    geom geometry(MultiPoint,3857),
    CONSTRAINT entrance_point_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.entrance_point OWNER to postgres;

insert into osm.entrance_point (osm_id, addr_flats, addr_housenumber, addr_street, addr_city, name, geom)
( select osm_id, "addr:flats",  "addr:housenumber", "addr:street", "addr:city", name, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_point
  where "addr:flats" is not null
);
delete from public.planet_osm_point where "addr:flats" is not null;

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу Подъездов.';
    END;
$$;

-- Строим таблицу Остального хлама

CREATE TABLE osm.other_point
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    addr_housenumber text,
    addr_street text, street_id uuid,
    addr_city text, city_id uuid,
    addr_district text, district_id uuid,
    addr_reg text, reg_id uuid,
    building text,
    construction text,
    disused text,
    historic text,
    name text,
    name_orig text,
    name_ru text,
    name_ru_orig text,
    operator text,
    ref text,
    religion text,
    service text,
    sport text,
    tourism text,
    geom geometry(MultiPoint,3857),
    CONSTRAINT other_point_pkey PRIMARY KEY (gid)
);

ALTER TABLE osm.other_point OWNER to postgres;

insert into osm.other_point (osm_id, addr_housenumber, addr_street, addr_city, building, construction, disused, historic, name, operator, ref, religion, service, sport, tourism, geom)
( select osm_id, "addr:housenumber", "addr:street", "addr:city", building, construction, disused, historic, name, operator, ref, religion, service, sport, tourism, case when ST_IsValid(ST_Multi(way)) then ST_Multi(way) else null end
  from public.planet_osm_point
);
delete from public.planet_osm_point where true;

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу точек.';
    END;
$$;

DO $$
    BEGIN
	RAISE INFO 'Все таблицы успешно построены.';
    END;
$$;

--------------------------------------------------------------------------------------------------------
-- Добавление данных из ручного редактирования
--------------------------------------------------------------------------------------------------------
-- Добавляем районы из нарисованных вручную
delete from osm.regions where hand is not null;

insert into osm.regions (gid, admin_level, name, hand, geom, geom_uniq)
                  select gid, admin_level, name, 'handadd',
                         case when ST_IsValid(ST_Multi(geom)) then ST_Multi(geom) else null end,
                         case when ST_IsValid(ST_Multi(geom)) then ST_Multi(geom) else null end
                  from hand.regions;

DO $$
    BEGIN
	RAISE INFO 'Добавили районы нарисованные вручную.';
    END;
$$;

--------------------------------------------------------------------------------------------------------
-- Добавляем населенные пункты из нарисованных вручную
delete from osm.settlements where hand is not null;

insert into osm.settlements (gid, admin_level, name, hand, geom, geom_uniq)
                      select gid, admin_level, name, 'handadd',
                             case when ST_IsValid(geom) then geom else null end,
                             case when ST_IsValid(geom) then geom else null end
                      from hand.settlements;

DO $$
    BEGIN
	RAISE INFO 'Добавили населенные пункты нарисованные вручную.';
    END;
$$;

--------------------------------------------------------------------------------------------------------
-- Добавляем дороги из нарисованных вручную

delete from osm.roads where hand is not null;

insert into osm.roads (gid, name, hand, geom)
                select gid, name, roadtype, case when ST_IsValid(geom) then geom else null end
                from hand.roads;

DO $$
    BEGIN
	RAISE INFO 'Добавили дороги нарисованные вручную.';
    END;
$$;

--------------------------------------------------------------------------------------------------------
-- Добавляем воду из нарисованных вручную
delete from osm.water where hand is not null;

insert into osm.water (gid, name, hand, geom)
                      select gid, name, 'handadd', case when ST_IsValid(geom) then geom else null end
                      from hand.water;

DO $$
    BEGIN
	RAISE INFO 'Добавили водные объекты нарисованные вручную.';
    END;
$$;

--------------------------------------------------------------------------------------------------------
-- Добавляем парки из нарисованных вручную

delete from osm.parks where hand is not null;

insert into osm.parks (gid, name, hand, geom)
                select gid, name, 'handadd', case when ST_IsValid(geom) then geom else null end
                from hand.parks;

DO $$
    BEGIN
	RAISE INFO 'Добавили парки нарисованные вручную.';
    END;
$$;

--------------------------------------------------------------------------------------------------------
-- Добавляем площади из нарисованных вручную

delete from osm.square where hand is not null;

insert into osm.square (gid, name, hand, geom)
                 select gid, name, 'handadd', case when ST_IsValid(geom) then geom else null end
                 from hand.square;

DO $$
    BEGIN
	RAISE INFO 'Добавили площади нарисованные вручную.';
    END;
$$;

--------------------------------------------------------------------------------------------------------
-- Добавляем острова из нарисованных вручную

delete from osm.island where hand is not null;

insert into osm.island (gid, name, hand, geom)
                 select gid, name, 'handadd', case when ST_IsValid(geom) then geom else null end
                 from hand.island;

DO $$
    BEGIN
	RAISE INFO 'Добавили острова нарисованные вручную.';
    END;
$$;

--------------------------------------------------------------------------------------------------------
-- Добавляем форты из нарисованных вручную

delete from osm.forts where hand is not null;

insert into osm.forts (gid, addr_housenumber, addr_street, name, hand, geom)
                select gid, addr_housenumber, addr_street, name, 'handadd', case when ST_IsValid(geom) then geom else null end
                from hand.forts;

DO $$
    BEGIN
	RAISE INFO 'Добавили форты нарисованные вручную.';
    END;
$$;

--------------------------------------------------------------------------------------------------------
-- Добавляем дома(строения) из нарисованных вручную

delete from osm.buildings where hand is not null;

insert into osm.buildings (gid, addr_housenumber, addr_street, building, name, hand, geom)
                    select gid, addr_housenumber, addr_street, buildingtype, name, 'handadd', case when ST_IsValid(geom) then geom else null end
                    from hand.buildings;
DO $$
    BEGIN
	RAISE INFO 'Добавили дома(строения) нарисованные вручную.';
    END;
$$;

--------------------------------------------------------------------------------------------------------
-- Добавляем ж/д станции из нарисованных вручную

delete from osm.railway_point where hand is not null;

insert into osm.railway_point (gid, addr_housenumber, addr_street, name, hand, geom)
                        select gid, addr_housenumber, addr_street, name, 'handadd', case when ST_IsValid(geom) then geom else null end
                        from hand.railway_point;
DO $$
    BEGIN
	RAISE INFO 'Добавили ж/д станции нарисованные вручную.';
    END;
$$;

--------------------------------------------------------------------------------------------------------
-- Добавляем километровые столбы из нарисованных вручную

delete from osm.milestone_point where hand is not null;

insert into osm.milestone_point (gid, distance, name, hand, geom)
                          select gid, distance, name, 'handadd', case when ST_IsValid(st_multi(geom)) then st_multi(geom) else null end
                          from hand.milestone_point;
DO $$
    BEGIN
	RAISE INFO 'Добавили километровые столбы нарисованные вручную.';
    END;
$$;

--------------------------------------------------------------------------------------------------------

Update osm.settlements set admin_level = case
    when place = 'yes' then 50
    when place = 'allotments' then 50
    when place = 'neighbourhood' then 50
    when place = 'suburb' then 40
    when place = 'hamlet' then 40
    when place = 'village' then 30
    when place = 'town' then 20
    when place = 'city' then 10 end where true;

Update osm.settlements set admin_level = 50 where admin_level is null and st_area(geom)/1000000 < 10;


DO $$
    BEGIN
	RAISE INFO 'Прописали уровни для населенных пунктов.';
    END;
$$;

-- Обработка  адресов

--------------------------------------------------------------------------------------------------------
-- Переименование объектов в разных таблицах
DO $$
  declare rec hand.torename%rowtype;
begin
 for rec in select * from hand.torename
  LOOP
    if rec.newname is null then
 		execute 'Update '||rec.tablename||' set '||rec.fieldname||'= null WHERE osm_id = '||rec.osm_id;
	else
  		execute 'Update '||rec.tablename||' set '||rec.fieldname||'='''||rec.newname||''' WHERE osm_id = '||rec.osm_id;
	end if;
	RAISE INFO 'Переименовали объекты в разных таблицах. %,  %,  %',rec.tablename, rec.fieldname, rec.newname;
  END LOOP;
end
$$;

DO $$
    BEGIN
	RAISE INFO 'Переименовали объекты в разных таблицах.';
    END;
$$;
--------------------------------------------------------------------------------------------------------
-- Удаление объектов в разных таблицах
DO $$
  declare tabName text;
begin
  for tabName in select tablename from hand.todelete
  LOOP
    execute 'Delete from '||tabName||' WHERE osm_id in (select osm_id from hand.todelete where tablename='''||tabName||''') ';
  END LOOP;
end;
$$;

DO $$
    BEGIN
	RAISE INFO 'Удалили объекты в разных таблицах.';
    END;
$$;

-------------------------------------------------------------------------------------------------------

DO $$
    BEGIN
	update osm.settlements set
               name_orig  = name,
               geonim_name = geonim('settlement','name', name),
               geonim_type = geonim('settlement','type', name)
	where name is not null;
	update osm.settlements set name = COALESCE(geonim_name||' '|| geonim_type, name)
	where name is not null;
    END;
$$;

DO $$
    BEGIN
	RAISE INFO 'Исправили наименования населенных пунктов.';
    END;
$$;
--------------------------------------------------------------------------------------------------------

-- Парсинг домов
DO $$
    BEGIN
	UPDATE osm.buildings SET house_number = addr_housenumber where true;
    END;
$$;
DO $$
    BEGIN
	RAISE INFO 'DATA FROM THE COLUMNS addr_housenumber AND addr_street ARE ADDED TO THE COLUMN HOUSE_NUMBER.';
    END;
$$;

DO $$
    BEGIN
	update osm.buildings set house_road_link = house_number WHERE house_number SIMILAR TO '%\sкм%';
	update osm.buildings set house_number = NULL WHERE house_number SIMILAR TO '%\sкм%';
    END;
$$;
DO $$
    BEGIN
	RAISE INFO 'THE HOUSE_NUMBER COLUMN WITH THE SUBSTRING "KM" WAS ADDED TO THE HOUSE_ROAD_LINK COLUMN, THE DATA OF THE HOUSE_NUMBER COLUMN WAS CLEARED FOR THESE ROWS.';
    END;
$$;

DO $$
    BEGIN
	update osm.buildings set
	house_number = substring(house_number from 0 for position( trim(both ' ' from substring(house_number from '\s{1,2}(л[а-я]{0,10}[А-Я]{1,5})')) in house_number)),
	house_litera = trim(both ' ' from substring(house_number from '\s{1,2}л[а-я]{0,10}([А-Я]{1,5}\d{0,2})'))
	WHERE addr_housenumber SIMILAR TO '%\sл\D{0,10}%' and addr_housenumber not like '%/%';
    END;
$$;
DO $$
    BEGIN
	RAISE INFO 'THE LETTER DATA FROM THE HOUSE_NUMBER COLUMN IS ADDED TO THE HOUSE_LITERA COLUMN.';
    END;
$$;

DO $$
    BEGIN
	update osm.buildings set
	house_number = substring(house_number from 0 for position( trim(both ' ' from substring(house_number from '\s{1,2}(с[а-я]{0,10}[А-Я]{0,5}\d{0,2})')) in house_number)),
	house_stroenie = trim(both ' ' from substring(house_number from '\s{1,2}с[а-я]{0,10}([А-Я]{0,5}\d{0,2})'))
	WHERE addr_housenumber SIMILAR TO '%\s{1,2}с[а-я]{0,10}[А-Я]{0,5}\d{0,2}%' and addr_housenumber not like '%/%';
    END;
$$;
DO $$
    BEGIN
	RAISE INFO 'osm.buildings DATA FROM THE HOUSE_NUMBER COLUMN IS ADDED TO THE HOUSE_STROENIE COLUMN.';
    END;
$$;

DO $$
    BEGIN
	update osm.buildings set
	house_number = substring(house_number from 0 for position( trim(both ' ' from substring(house_number from '\s{1,2}(к[а-я]{0,10}\d{0,2}[А-Я]{0,5})')) in house_number)),
	house_korpus = trim(both ' ' from substring(house_number from '\s{1,2}к[а-я]{0,10}(\d{0,2}[А-Я]{0,5})' ))
	WHERE addr_housenumber SIMILAR TO '%\s{1,2}к[а-я]{0,10}(\d{0,2}[А-Я]{0,5})%' and addr_housenumber not like '%/%';
    END;
$$;
DO $$
    BEGIN
	RAISE INFO 'THE HOUSE NUMBER OF THE HOUSE_NUMBER COLUMN IS ADDED TO THE HOUSE_KORPUS COLUMN.';
    END;
$$;

DO $$
    BEGIN
	update osm.buildings set
	house_korpus = trim(both ' ' from substring(house_korpus from '(\d{1,3})[А-Я]{1,5}')),
	house_litera = trim(both ' ' from concat(house_litera, ' ', substring(house_korpus from '\d{1,3}([А-Я]{1,5})')))
	WHERE house_korpus SIMILAR TO '%\d{1,3}[А-Я]{1,5}%' and addr_housenumber not like '%/%';
    END;
$$;
DO $$
    BEGIN
	RAISE INFO 'A LETTER FROM THE HOUSE_KORP COLUMN HAS BEEN ADDED TO THE HOUSE_LITERA FIELD.';
    END;
$$;

DO $$
    BEGIN
	update osm.buildings set
	house_number = trim(both ' ' from substring(house_number from '(\d{1,3})[А-Я]{1,5}')),
	house_litera = trim(both ' ' from concat(substring(house_number from '\d{1,3}([А-Я]{1,5})'), house_litera))
	WHERE house_number SIMILAR TO '%\d{1,3}[А-Я]{1,5}%' and addr_housenumber not like '%/%';
    END;
$$;
DO $$
    BEGIN
	RAISE INFO 'A LETTER FROM THE HOUSE_NUMBER COLUMN IS ADDED TO THE HOUSE_LITERA FIELD.';
    END;
$$;

-- #######################################################################################################################
--
-- приводим в порядок линии и дома В.О.
--
-- #######################################################################################################################

INSERT INTO osm.roads(osm_id, highway, name, hand, geom)
(
  with -- в теории, неплохо бы добавить проверку на вхождение в полигон Василевского острова
  st1 as (select gid, osm_id, highway, geom, trim(both from replace(replace(substring(lower(name) from '((\d\d?)|(\d\d?\s?s?-s?\s?\d\d?))'), ' ',''), ' ','')) as name from osm.roads where name ilike '%линии%В%О%'),
  st2 as (select *, substring(name from '^\d\d?') as name1, substring(name from '^\d\d?')::int%2 as hn1, replace(substring(name from '-\d\d?'), '-','') as name2, replace(substring(name from '-\d\d?'), '-','')::int%2  as hn2 from st1 where name is not null),
  sta as (select gid, osm_id, geom, highway, case when hn1 = 1 then name1 when hn2 = 1 then name2 end as name from st2),
  str as (select gid, highway, case when hn1 = 0 then name1 when hn2 = 0 then name2 else null end as name from st2)
  select osm_id, highway, name||'-я линия В.О.', 'handaddvo' as name, case when ST_IsValid(ST_Multi(ST_OffsetCurve(geom, -10))) then ST_Multi(ST_OffsetCurve(geom, -10)) else null end
  from sta where name is not null
);
update osm.roads r set geom=ren.geom
from
(
  with -- в теории, неплохо бы добавить проверку на вхождение в полигон Василевского острова
  st1 as (select gid, osm_id, highway, geom, trim(both from replace(replace(substring(lower(name) from '((\d\d?)|(\d\d?\s?s?-s?\s?\d\d?))'), ' ',''), ' ','')) as name from osm.roads where name ilike '%линии%В%О%'),
  st2 as (select *, substring(name from '^\d\d?') as name1, substring(name from '^\d\d?')::int%2 as hn1, replace(substring(name from '-\d\d?'), '-','') as name2, replace(substring(name from '-\d\d?'), '-','')::int%2  as hn2 from st1 where name is not null),
  sta as (select gid, osm_id, geom, highway, case when hn1 = 1 then name1 when hn2 = 1 then name2 end as name from st2),
  str as (select gid, geom, highway, case when hn1 = 0 then name1 when hn2 = 0 then name2 else null end as name from st2)
  select gid, case when ST_IsValid(ST_Multi(ST_OffsetCurve(geom, 10))) then ST_Multi(ST_OffsetCurve(geom, 10)) else null end as geom
  from str where name is not null
) ren
where r.gid = ren.gid;

update osm.roads r set hand = r.name, name=ren.name
from
(
  with   -- в теории, неплохо бы добавить проверку на вхождение в полигон Василевского острова
  st1 as (select gid, osm_id, highway, geom, trim(both from replace(replace(substring(lower(name) from '((\d\d?)|(\d\d?\s?s?-s?\s?\d\d?))'), ' ',''), ' ','')) as name from osm.roads where name ilike '%линии%В%О%'),
  st2 as (select *, substring(name from '^\d\d?') as name1, substring(name from '^\d\d?')::int%2 as hn1, replace(substring(name from '-\d\d?'), '-','') as name2, replace(substring(name from '-\d\d?'), '-','')::int%2  as hn2 from st1 where name is not null),
  sta as (select gid, osm_id, geom, highway, case when hn1 = 1 then name1 when hn2 = 1 then name2 end as name from st2),
  str as (select gid, highway, case when hn1 = 0 then name1 when hn2 = 0 then name2 else null end as name from st2)
  select gid, name||'-я линия В.О.' as name from str where name is not null
) ren
where r.gid = ren.gid;

DO $$
    BEGIN
	RAISE INFO 'Преобразовали линии В.О.';
    END;
$$;

update osm.buildings r set addr_street=ren.street
from
(
  with  -- в теории, неплохо бы добавить проверку на вхождение в полигон Василевского острова
  hs1 as (select gid, substring(lower(addr_housenumber) from '\d{1,3}') as house_num, trim(both from replace(replace(substring(lower(addr_street) from '((\d\d?)|(\d\d?\s?s?-s?\s?\d\d?))'), ' ',''), ' ','')) as name from osm.buildings where addr_street ilike '%линии%В%О%'
          union
          select gid, substring(lower(addr_housenumber) from '\d{1,3}') as house_num, trim(both from replace(replace(substring(lower(addr_street) from '((\d\d?)|(\d\d?\s?s?-s?\s?\d\d?))'), ' ',''), ' ','')) as name from osm.buildings where addr_street ilike '%линия%В%О%'),
  hs2 as (select *, house_num::int%2 as house_nch, substring(name from '^\d\d?')::int%2 as nch1, replace(substring(name from '-\d\d?'), '-','')::int%2  as nch2,
  		substring(name from '^\d\d?') as name1, replace(substring(name from '-\d\d?'), '-','') as name2
  		from hs1 where name is not null),
  hs3 as (select *,
  		case when nch1 = 1 then name1 when nch2 = 1 then name2 else null end as name1t,
  		case when nch1 = 0 then name1 when nch2 = 0 then name2 else null end as name2t from hs2),
  hs4 as (select *,
  		case when name1t is null and name2t is not null then (name2t::int+1)::text else name1t end as name_nch,
  		case when name2t is null and name1t is not null then (name1t::int-1)::text else name2t end as name_ch from hs3)
  select gid, (case when house_nch = 1 then name_ch when house_nch = 0 then name_nch else name1 end )||'-я линия В.О.' as street from hs4
) ren
where r.gid = ren.gid;

DO $$
    BEGIN
	RAISE INFO 'Преобразовали дома линий В.О.';
    END;
$$;

-- #######################################################################################################################

delete from osm.forts where geom is null;
delete from osm.cemetery where geom is null;
delete from osm.buildings where geom is null;
delete from osm.settlements where geom is null;
delete from osm.residential_complex where geom is null;
delete from osm.water where geom is null;
delete from osm.coast_line where geom is null;
delete from osm.water_line where geom is null;
delete from osm.bridges where geom is null;
delete from osm.regions where geom is null;
delete from osm.parks where geom is null;
delete from osm.reserve_parks where geom is null;
delete from osm.square where geom is null;
delete from osm.railway_platform where geom is null;
delete from osm.industrial where geom is null;
delete from osm.commercial where geom is null;
delete from osm.commercial_point where geom is null;
delete from osm.education where geom is null;
delete from osm.education_point where geom is null;
delete from osm.island where geom is null;
delete from osm.landuse where geom is null;
delete from osm.landuse_line where geom is null;
delete from osm.route where geom is null;
delete from osm.route_stop where geom is null;
delete from osm.railway where geom is null;
delete from osm.railway_point where geom is null;
delete from osm.highways where geom is null;
delete from osm.roads where geom is null;
delete from osm.milestone_point where geom is null;
delete from osm.barrier where geom is null;
delete from osm.barrier_point where geom is null;
delete from osm.power_line where geom is null;
delete from osm.power_point where geom is null;
delete from osm.entrance_point where geom is null;
delete from osm.other_point where geom is null;