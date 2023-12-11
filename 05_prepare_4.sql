--Удаление таблиц
CREATE SCHEMA IF NOT EXISTS addr AUTHORIZATION postgres;

DROP TABLE IF EXISTS addr.regions, addr.districts, addr.municipal_districts, addr.settlements, addr.streets, addr.addrobj, addr.buildings;

DO $$
    BEGIN
	RAISE INFO 'Удалили таблицы.';
    END;
$$;
---------------------------

-- Строим таблицу Районов, округов

CREATE TABLE addr.regions
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    v2_id bigint,
    name text,
    name_orig text,
    hand text,
    geonim_name text,
    geonim_type text,
    geom geometry(MultiPolygon,3857),
    geom_uniq geometry(MultiPolygon,3857),
    CONSTRAINT regions_pkey PRIMARY KEY (gid)
);

ALTER TABLE addr.regions OWNER to postgres;

DROP INDEX IF EXISTS addr.addr_city_regions,addr.addr_district_regions,addr.addr_reg_regions,addr.name_regions,addr.geonim_name_regions,addr.geonim_type_regions;

DROP INDEX IF EXISTS addr.geom_regions, addr.geom_uniq_regions;
CREATE INDEX geom_regions ON addr.regions USING GIST ( geom );
CREATE INDEX geom_uniq_regions ON addr.regions USING GIST ( geom_uniq );

CREATE INDEX name_regions ON addr.regions USING HASH (name);
CREATE INDEX geonim_name_regions ON addr.regions USING HASH (geonim_name);
CREATE INDEX geonim_type_regions ON addr.regions USING HASH (geonim_type);

insert into addr.regions (gid, osm_id, name, name_orig, hand, geonim_name, geonim_type, geom, geom_uniq)
(
  select nr.gid, nr.osm_id, nr.name, nr.name_orig, nr.hand, nr.geonim_name, nr.geonim_type, nr.geom, nr.geom_uniq
  from osm.regions nr
  where nr.name is not null and nr.admin_level = 4
);

CREATE TABLE addr.districts
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    v2_id bigint,
    region text,
    regionId uuid,
    admin_level smallint,
    name text,
    name_orig text,
    hand text,
    geonim_name text,
    geonim_type text,
    geom geometry(MultiPolygon,3857),
    geom_uniq geometry(MultiPolygon,3857),
    CONSTRAINT districts_pkey PRIMARY KEY (gid)
);

ALTER TABLE addr.districts OWNER to postgres;

DROP INDEX IF EXISTS addr.addr_city_districts,addr.addr_district_districts,addr.addr_reg_districts,addr.name_districts,addr.geonim_name_districts,addr.geonim_type_districts;

DROP INDEX IF EXISTS addr.geom_districts, addr.geom_uniq_districts;
CREATE INDEX geom_districts ON addr.districts USING GIST ( geom );
CREATE INDEX geom_uniq_districts ON addr.districts USING GIST ( geom_uniq );

CREATE INDEX addr_reg_districts ON addr.districts USING HASH (region);
CREATE INDEX name_districts ON addr.districts USING HASH (name);
CREATE INDEX geonim_name_districts ON addr.districts USING HASH (geonim_name);
CREATE INDEX geonim_type_districts ON addr.districts USING HASH (geonim_type);

insert into addr.districts (gid, osm_id, region, regionId, admin_level, name, name_orig, hand, geonim_name, geonim_type, geom, geom_uniq)
(
  select nr.gid, nr.osm_id, nr.addr_reg, nr.reg_id, nr.admin_level, nr.name, nr.name_orig, nr.hand, nr.geonim_name, nr.geonim_type, nr.geom, nr.geom_uniq
  from osm.regions nr
  where nr.name is not null and nr.admin_level in (5,6)
);

CREATE TABLE addr.municipal_districts
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    v2_id bigint,
    city text,
    cityId uuid,
    district text,
    districtId uuid,
    region text,
    regionId uuid,
    admin_level smallint,
    name text,
    name_orig text,
    hand text,
    geonim_name text,
    geonim_type text,
    geom geometry(MultiPolygon,3857),
    geom_uniq geometry(MultiPolygon,3857),
    CONSTRAINT municipal_districts_pkey PRIMARY KEY (gid)
);

ALTER TABLE addr.municipal_districts OWNER to postgres;

DROP INDEX IF EXISTS addr.addr_city_municipal_districts,addr.addr_district_municipal_districts,addr.addr_reg_municipal_districts,addr.name_municipal_districts,addr.geonim_name_municipal_districts,addr.geonim_type_municipal_districts;

DROP INDEX IF EXISTS addr.geom_municipal_districts, addr.geom_uniq_municipal_districts;
CREATE INDEX geom_municipal_districts ON addr.municipal_districts USING GIST ( geom );
CREATE INDEX geom_uniq_municipal_districts ON addr.municipal_districts USING GIST ( geom_uniq );

CREATE INDEX addr_city_municipal_districts ON addr.municipal_districts USING HASH (city);
CREATE INDEX addr_district_municipal_districts ON addr.municipal_districts USING HASH (district);
CREATE INDEX addr_reg_municipal_districts ON addr.municipal_districts USING HASH (region);
CREATE INDEX name_municipal_districts ON addr.municipal_districts USING HASH (name);
CREATE INDEX geonim_name_municipal_districts ON addr.municipal_districts USING HASH (geonim_name);
CREATE INDEX geonim_type_municipal_districts ON addr.municipal_districts USING HASH (geonim_type);

insert into addr.municipal_districts (gid, osm_id, city, cityId, district, districtId, region, regionId, admin_level, name, name_orig, hand, geonim_name, geonim_type, geom, geom_uniq)
(
  select nr.gid, nr.osm_id, nr.addr_city, nr.city_id, nr.addr_district, nr.district_id, nr.addr_reg, nr.reg_id, nr.admin_level, nr.name, nr.name_orig, nr.hand, nr.geonim_name, nr.geonim_type, nr.geom, nr.geom_uniq
  from osm.regions nr
  where nr.name is not null and nr.admin_level > 6
);

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу Районов, округов.';
    END;
$$;

-- Строим таблицу Населенных пунктов
CREATE TABLE addr.settlements
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    v2_id bigint,
    city text,
    cityId uuid,
    district text,
    districtId uuid,
    region text,
    regionId uuid,
    admin_level smallint,
    name text,
    name_orig text,
    hand text,
    fullname text[],
    fullId uuid[],
    geonim_name text,
    geonim_type text,
    updated boolean,
    geom geometry(MultiPolygon,3857),
    geom_uniq geometry(MultiPolygon,3857),
    CONSTRAINT settlements_pkey PRIMARY KEY (gid)
);

ALTER TABLE addr.settlements OWNER to postgres;

DROP INDEX IF EXISTS addr.addr_city_settlements, addr.addr_city_full_settlements, addr.addr_district_settlements, addr.addr_reg_settlements, addr.name_settlements, addr.fullname_settlements, addr.fullpath_settlements, addr.place_settlements, addr.geonim_name_settlements, addr.geonim_type_settlements;

DROP INDEX IF EXISTS addr.geom_settlements, addr.geom_uniq_settlements;
CREATE INDEX geom_settlements ON addr.settlements USING GIST ( geom );
CREATE INDEX geom_uniq_settlements ON addr.settlements USING GIST ( geom_uniq );

CREATE INDEX addr_city_settlements ON addr.settlements USING HASH (city);
CREATE INDEX addr_city_full_settlements ON addr.settlements USING HASH (fullname);
CREATE INDEX addr_district_settlements ON addr.settlements USING HASH (district);
CREATE INDEX addr_reg_settlements ON addr.settlements USING HASH (region);
CREATE INDEX name_settlements ON addr.settlements USING HASH (name);
CREATE INDEX fullname_settlements ON addr.settlements USING HASH (fullname);
CREATE INDEX fullpath_settlements ON addr.settlements USING HASH (fullId);
CREATE INDEX geonim_name_settlements ON addr.settlements USING HASH (geonim_name);
CREATE INDEX geonim_type_settlements ON addr.settlements USING HASH (geonim_type);

insert into addr.settlements (gid, osm_id, city, cityId, district, districtId, region, regionId, admin_level, name, name_orig, hand, fullname, fullId, geonim_name, geonim_type, geom, geom_uniq)
(
    select ns.gid, ns.osm_id, ns.addr_city, ns.city_id, ns.addr_district, ns.district_id, ns.addr_reg, ns.reg_id, ns.admin_level, ns.name, ns.name_orig, ns.hand, ns.fullname, ns.fullpath, ns.geonim_name, ns.geonim_type, ns.geom, ns.geom_uniq
    from osm.settlements ns
    where name is not null
);

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу Районов, округов.';
    END;
$$;

-- Строим таблицу Автомагистралей (ЗСД, КАД)

CREATE TABLE addr.streets
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    global_gid uuid,
    osm_id bigint,
    v2_id bigint,
    v2_namenum integer,
    city text,
    cityId uuid,
    district text,
    districtId uuid,
    region text,
    regionId uuid,
    name text,
    name_orig text,
    hand text,
    source text,
    geonim_name text,
    geonim_type text,
    geom geometry(MultiLineString,3857),
    CONSTRAINT streets_pkey PRIMARY KEY (gid)
);

ALTER TABLE addr.streets OWNER to postgres;

DROP INDEX IF EXISTS addr.addr_city_highways,addr.addr_district_highways,addr.addr_reg_highways,addr.name_highways,addr.geonim_name_highways,addr.geonim_type_highways;
DROP INDEX IF EXISTS addr.addr_city_streets,addr.addr_district_streets,addr.addr_reg_streets,addr.name_streets,addr.geonim_name_streets, addr.geonim_type_streets;

DROP INDEX IF EXISTS addr.geom_streets;
CREATE INDEX geom_streets ON addr.streets USING GIST ( geom );

CREATE INDEX addr_city_streets ON addr.streets USING HASH (city);
CREATE INDEX addr_district_streets ON addr.streets USING HASH (district);
CREATE INDEX addr_reg_streets ON addr.streets USING HASH (region);
CREATE INDEX name_streets ON addr.streets USING HASH (name);
CREATE INDEX geonim_name_streets ON addr.streets USING HASH (geonim_name);
CREATE INDEX geonim_type_streets ON addr.streets USING HASH (geonim_type);

delete from addr.streets where source='highways';
insert into addr.streets (gid, osm_id, city, cityId, district, districtId, region, regionId, name, name_orig, hand, source, geonim_name, geonim_type, geom)
(
    select nh.gid, nh.osm_id, nh.addr_city, nh.city_id, nh.addr_district, nh.district_id, nh.addr_reg, nh.reg_id, nh.name, nh.name_orig, nh.hand, 'highways', nh.geonim_name, nh.geonim_type, nh.geom
    from osm.highways nh
    where name is not null
);

-- delete from addr.streets where source='roads';
insert into addr.streets (gid, osm_id, city, cityId, district, districtId, region, regionId, name, name_orig, hand, source, geonim_name, geonim_type, geom)
(
    select nh.gid, nh.osm_id, nh.addr_city, nh.city_id, nh.addr_district, nh.district_id, nh.addr_reg, nh.reg_id, nh.name, nh.name_orig, nh.hand, 'roads', nh.geonim_name, nh.geonim_type, nh.geom
    from osm.roads nh
    where name is not null
);

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу Автомагистралей (ЗСД, КАД).';
    END;
$$;

-- Строим таблицу addr.addrobj
CREATE TABLE addr.addrobj
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    global_gid uuid,
    osm_id bigint,
    v2_id bigint,
    v2_namenum integer,
    street text,
    streetId uuid,
    city text,
    cityId uuid,
    district text,
    districtId uuid,
    region text,
    regionId uuid,
    name text,
    name_orig text,
    hand text,
    source text,
    geonim_name text,
    geonim_type text,
    geom geometry,
    CONSTRAINT addrobj_pkey PRIMARY KEY (gid)
);

ALTER TABLE addr.addrobj OWNER to postgres;

DROP INDEX IF EXISTS addr.addr_city_addrobj,addr.addr_district_addrobj,addr.addr_reg_addrobj,
    addr.name_addrobj,addr.geonim_name_addrobj,addr.geonim_type_addrobj,addrobj_source_index, addrobj_street_index;


DROP INDEX IF EXISTS addr.geom_addrobj;
CREATE INDEX geom_addrobj ON addr.addrobj USING GIST ( geom );

CREATE INDEX addr_city_ ON addr.addrobj USING HASH (city);
CREATE INDEX addr_district_addrobj ON addr.addrobj USING HASH (district);
CREATE INDEX addr_reg_addrobj ON addr.addrobj USING HASH (region);
CREATE INDEX name_addrobj ON addr.addrobj USING HASH (name);
CREATE INDEX geonim_name_addrobj ON addr.addrobj USING HASH (geonim_name);
CREATE INDEX geonim_type_addrobj ON addr.addrobj USING HASH (geonim_type);

create index addrobj_source_index on addr.addrobj (source);
create index addrobj_street_index on addr.addrobj (street);

insert into addr.addrobj (gid, osm_id, street, streetId, city, cityId, district, districtId, region, regionId, name, name_orig, hand, source, geonim_name, geonim_type, geom)
(
    select ns.gid, ns.osm_id, ns.addr_street, ns.street_id, ns.addr_city, ns.city_id, ns.addr_district, ns.district_id, ns.addr_reg, ns.reg_id, ns.name, ns.name_orig, null, 'forts', ns.name, null, ns.geom
    from osm.forts ns
    where name is not null
);
insert into addr.addrobj (gid, osm_id, street, streetId, city, cityId, district, districtId, region, regionId, name, name_orig, hand, source, geonim_name, geonim_type, geom)
(
    select ns.gid, ns.osm_id, ns.addr_street, ns.street_id, ns.addr_city, ns.city_id, ns.addr_district, ns.district_id, ns.addr_reg, ns.reg_id, ns.name, ns.name_orig, null, 'cemetery', ns.name, null, ns.geom
    from osm.cemetery ns
    where name is not null
);
insert into addr.addrobj (gid, osm_id, street, streetId, city, cityId, district, districtId, region, regionId, name, name_orig, hand, source, geonim_name, geonim_type, geom)
(
    select nrk.gid, nrk.osm_id, null, null, nrk.addr_city, nrk.city_id, nrk.addr_district, nrk.district_id, nrk.addr_reg, nrk.reg_id, nrk.name, nrk.name_orig, nrk.hand, 'residential_complex', nrk.geonim_name, nrk.geonim_type, nrk.geom
    from osm.residential_complex nrk
    where name is not null
);

insert into addr.addrobj (gid, osm_id, street, streetId, city, cityId, district, districtId, region, regionId, name, name_orig, hand, source, geonim_name, geonim_type, geom)
(
    select nw.gid, nw.osm_id, null, null, nw.addr_city, nw.city_id, nw.addr_district, nw.district_id, nw.addr_reg, nw.reg_id, nw.name, nw.name_orig, nw.hand, 'water', geonim_name('water', nw.name), geonim_type('water', nw.name), nw.geom
    from osm.water nw
    where name is not null
);
insert into addr.addrobj (gid, osm_id, street, streetId, city, cityId, district, districtId, region, regionId, name, name_orig, hand, source, geonim_name, geonim_type, geom)
(
    select nw.gid, nw.osm_id, null, null, nw.addr_city, nw.city_id, nw.addr_district, nw.district_id, nw.addr_reg, nw.reg_id, nw.name, nw.name_orig, null, 'water_line', geonim_name('water', nw.name), geonim_type('water', nw.name), nw.geom
    from osm.water_line nw
    where name is not null
);
--delete from addr.addrobj where source='bridges';
insert into addr.addrobj (gid, osm_id, street, streetId, city, cityId, district, districtId, region, regionId, name, name_orig, hand, source, geonim_name, geonim_type, geom)
(
    select nb.gid, nb.osm_id, nb.addr_street, nb.street_id, nb.addr_city, nb.city_id, nb.addr_district, nb.district_id, nb.addr_reg, nb.reg_id, nb.name, nb.name_orig, null, 'bridges', geonim_name('str', nb.name), geonim_type('str', nb.name), nb.geom
    from osm.bridges nb
    where name is not null
);
insert into addr.addrobj (gid, osm_id, street, streetId, city, cityId, district, districtId, region, regionId, name, name_orig, hand, source, geonim_name, geonim_type, geom)
(
    select np.gid, np.osm_id, np.addr_street, np.street_id, np.addr_city, np.city_id, np.addr_district, np.district_id, np.addr_reg, np.reg_id, np.name, np.name_orig, np.hand, 'parks', np.name, null, np.geom
    from osm.parks np
    where name is not null
);

--delete from addr.addrobj where source='reserve_parks';
insert into addr.addrobj (gid, osm_id, street, streetId, city, cityId, district, districtId, region, regionId, name, name_orig, hand, source, geonim_name, geonim_type, geom)
(
    select nrp.gid, nrp.osm_id, nrp.addr_street, nrp.street_id, nrp.addr_city, nrp.city_id, nrp.addr_district, nrp.district_id, nrp.addr_reg, nrp.reg_id, nrp.name, nrp.name_orig, null, 'reserve_parks', nrp.name, null, nrp.geom
    from osm.reserve_parks nrp
    where name is not null
);
--delete from addr.addrobj where source='square';
insert into addr.addrobj (gid, osm_id, street, streetId, city, cityId, district, districtId, region, regionId, name, name_orig, hand, source, geonim_name, geonim_type, geom)
(
    select ns.gid, ns.osm_id, ns.addr_street, ns.street_id, ns.addr_city, ns.city_id, ns.addr_district, ns.district_id, ns.addr_reg, ns.reg_id, ns.name, ns.name_orig, ns.hand, 'square', ns.name, null, ns.geom
    from osm.square ns
    where name is not null
);
insert into addr.addrobj (gid, osm_id, street, streetId, city, cityId, district, districtId, region, regionId, name, name_orig, hand, source, geonim_name, geonim_type, geom)
(
    select ni.gid, ni.osm_id, null, null, ni.addr_city, ni.city_id, ni.addr_district, ni.district_id, ni.addr_reg, ni.reg_id, ni.name, ni.name_orig, ni.hand, 'island', geonim_name('isl', ni.name), geonim_type('isl', ni.name), ni.geom
    from osm.island ni
    where name is not null
);
--delete from addr.addrobj where source='railway_point';
insert into addr.addrobj (gid, osm_id, street, streetId, city, cityId, district, districtId, region, regionId, name, name_orig, hand, source, geonim_name, geonim_type, geom)
(
    select nr.gid, nr.osm_id, nr.addr_street, nr.street_id, nr.addr_city, nr.city_id, nr.addr_district, nr.district_id, nr.addr_reg, nr.reg_id, nr.name, nr.name_orig, nr.hand, 'railway_point', nr.name, null, nr.geom
    from osm.railway_point nr
    where name is not null
);
--delete from addr.addrobj where source='milestone_point';
insert into addr.addrobj (gid, osm_id, street, streetId, city, cityId, district, districtId, region, regionId, name, name_orig, hand, source, geonim_name, geonim_type, geom)
(
    select nm.gid, nm.osm_id, nm.addr_street, nm.street_id, nm.addr_city, nm.city_id, nm.addr_district, nm.district_id, nm.addr_reg, nm.reg_id, nm.name, nm.name_orig, nm.hand, 'milestone_point', nm.name, null, nm.geom
    from osm.milestone_point nm
    where name is not null
);

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу адресных объектов.';
    END;
$$;
---------------------------

-- Строим таблицу домов

CREATE TABLE addr.buildings
(
    gid uuid NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    osm_id bigint,
    v2_id bigint,
    namenum integer,
    v2_namenum integer,
    flats text,
    housenumber text,
    housenumber_orig text,
    street text,
    streetId uuid,
    city text,
    cityId uuid,
    district text,
    districtId uuid,
    region text,
    regionId uuid,
    name text,
    name_orig text,
    hand text,
    source text,
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

ALTER TABLE addr.buildings OWNER to postgres;

DROP INDEX IF EXISTS addr.addr_housenumber_buildings, addr.addr_street_buildings, addr.addr_city_buildings,
    addr.addr_district_buildings, addr.addr_reg_buildings, addr.name_buildings, addr.geonim_name_buildings, addr.geonim_type_buildings;

DROP INDEX IF EXISTS addr.geom_buildings;
CREATE INDEX geom_buildings ON addr.buildings USING GIST ( geom );


CREATE INDEX addr_housenumber_buildings ON addr.buildings USING HASH (housenumber);

CREATE INDEX addr_city_buildings ON addr.buildings USING HASH (city);
CREATE INDEX addr_district_buildings ON addr.buildings USING HASH (district);
CREATE INDEX addr_reg_buildings ON addr.buildings USING HASH (region);
CREATE INDEX name_buildings ON addr.buildings USING HASH (name);
CREATE INDEX geonim_name_buildings ON addr.buildings USING HASH (geonim_name);
CREATE INDEX geonim_type_buildings ON addr.buildings USING HASH (geonim_type);

create index buildings_namenum_index  on addr.buildings (namenum);
create index buildings_street_index  on addr.buildings (street);


-- delete from addr.buildings where true;

insert into addr.buildings (gid, osm_id, street, streetId, city, cityId, district, districtId, region, regionId, name, name_orig, hand, source, geonim_name, geonim_type, geom, flats, housenumber, housenumber_orig, house_number, house_korpus, house_litera, house_stroenie, house_road_link)
(
    select ns.gid, ns.osm_id, ns.addr_street, ns.street_id, ns.addr_city, ns.city_id, ns.addr_district, ns.district_id, ns.addr_reg, ns.reg_id, ns.name, ns.name_orig, null, 'buildings', ns.name, null, ns.geom, addr_flats, addr_housenumber, addr_housenumber_orig, house_number, house_korpus, house_litera, house_stroenie, house_road_link
    from osm.buildings ns
    where addr_housenumber is not null
);

DO $$
    BEGIN
	RAISE INFO 'Построили таблицу домов.';
    END;
$$;
---------------------------



-- ####################################################################
-- -- Прописываем наименования региона, района, населенного пункта
-- ####################################################################

DO $$
    BEGIN
	update addr.regions set
               name_orig  = name,
               geonim_name = geonim('region','name', name),
               geonim_type = lower(geonim('region','type', name)) where true;
	update addr.regions set name  = COALESCE(geonim_name||' '|| geonim_type, name) where true;
    END;
$$;
DO $$
    BEGIN
	RAISE INFO 'Исправили наименования регионов, районов, муниципалитетов .';
    END;
$$;


-- Прописываем наименование региона в районы и округа
update addr.districts ds set region = rg.name, regionid = rg.reg_gid
from
(
 select s.gid, reg.gid as reg_gid, reg.name from addr.districts s join addr.regions reg on area50(reg.geom, s.geom)
) rg
where ds.gid = rg.gid;
DO $$
    BEGIN
	RAISE INFO 'Прописали наименование региона в районы и округа.';
    END;
$$;

-- Прописываем наименования района, региона в округа и поселения
update addr.municipal_districts md set district = rg.name, districtid = rg.dist_gid, region = rg.region , regionid = rg.regionid
from
(
 select s.gid, reg.region, reg.regionid, reg.gid as dist_gid, reg.name from addr.municipal_districts s right join addr.districts reg on area50(reg.geom, s.geom)
) rg
where md.gid = rg.gid;
DO $$
    BEGIN
	RAISE INFO 'Прописали наименования района в округа и поселения.';
    END;
$$;

-- -- Прописываем наименования региона, района в населенные пункты
update addr.settlements st set district = rg.name, districtid = rg.dist_gid, region = rg.region , regionid = rg.regionid
from
(
 select s.gid, reg.region, reg.regionid, reg.gid as dist_gid, reg.name from addr.settlements s right join addr.districts reg on area50(reg.geom, s.geom)
) rg
where st.gid = rg.gid;

DO $$
    BEGIN
	RAISE INFO 'Прописали наименования региона, района в населенные пункты.';
    END;
$$;

-- -- Прописываем наименования вложенных населенных пунктов в населенные пункты
DO $$
  declare setl addr.settlements%rowtype;
begin
  update addr.settlements set updated = false,
                             --city = geonim_name,
                             fullname = ARRAY[]::text[],
                             fullid = ARRAY[]::uuid[],
                             geom_uniq = geom where true;
  for setl in select * from addr.settlements order by st_area(geom) desc
  LOOP
      update addr.settlements st set updated = true where st.gid = setl.gid;
      update addr.settlements st set geom_uniq = COALESCE(case when st_IsValid(su.geom_uniq) then su.geom_uniq else st.geom end, st.geom)
      from
      (
        with ug as (select st_Union(geom) as ugeom from addr.settlements where updated = false and area50(setl.geom, geom)) --st_contains(setl.geom, geom))
        select ST_MULTI(ST_CollectionExtract(ST_Difference(setl.geom, ugeom), 3)) as geom_uniq from ug
      ) su
      where st.gid = setl.gid;
      update addr.settlements st set fullname = array_prepend(setl.geonim_name, st.fullname ),
                                     fullid = array_prepend(setl.gid, st.fullid)
      where updated = false and area50(setl.geom_uniq, geom);
      RAISE INFO '%',setl.name;
  END LOOP;
  update addr.settlements set city = array_to_string(array_prepend(geonim_name, fullname ), ',', ''),
                                     fullname = array_prepend(geonim_name, fullname ),
                                     fullid = array_prepend(gid, fullid)
      where true;
end;
$$;

DO $$
    BEGIN
	RAISE INFO 'Прописали наименования вложенных населенных пунктов в населенные пункты.';
    END;
$$;

-- #################################################################################################

-- -- Прописываем наименования региона, района, населенного пункта
update addr.addrobj ao set region = rg.region, regionid = rg.regionid, district = rg.district, districtid = rg.districtid, city = rg.name, cityid = rg.setl_gid
from (
 select s.gid, reg.region, reg.regionid, reg.district, reg.districtid, reg.gid as setl_gid, reg.name from addr.addrobj s right join addr.settlements reg on contains50(reg.geom_uniq, s.geom, s.gid::text||' -> '||s.source)
) rg
where ao.gid = rg.gid;

-- -- Прописываем наименования района
update addr.addrobj ao set region = rg.region, regionid = rg.regionid, district = rg.name, districtid = rg.dist_gid
from (
 select s.gid, reg.region, reg.regionid, reg.gid as dist_gid, reg.name from addr.addrobj s right join addr.districts reg on contains50(reg.geom, s.geom)
) rg
where ao.gid = rg.gid;

-- -- Прописываем наименования региона
update addr.addrobj ao set region = rg.name, regionid = rg.reg_gid
from (
 select s.gid, reg.gid as reg_gid, reg.name from addr.addrobj s right join addr.regions reg on contains50(reg.geom, s.geom)
) rg
where ao.gid = rg.gid;

DO $$
    BEGIN
	RAISE INFO 'Прописали наименования региона, района, населенного пункта в osm.forts';
    END;
$$;

 -- Прописываем наименования региона, района, населенного пункта
update addr.buildings bu set region = rg.region, regionid = rg.regionid, district = rg.district, districtid = rg.districtid, city = rg.name, cityid = rg.setl_gid
from (
 select s.gid, reg.region, reg.regionid, reg.district, reg.districtid, reg.gid as setl_gid, reg.name from addr.buildings s right join addr.settlements reg on contains50(reg.geom_uniq, s.geom, s.gid::text||' -> '||s.source)
) rg
where bu.gid = rg.gid;

-- -- Прописываем наименования района
update addr.buildings ao set region = rg.region, regionid = rg.regionid, district = rg.name, districtid = rg.dist_gid
from (
 select s.gid, reg.region, reg.regionid, reg.gid as dist_gid, reg.name from addr.buildings s right join addr.districts reg on contains50(reg.geom, s.geom)
) rg
where ao.gid = rg.gid;

-- -- Прописываем наименования региона
update addr.buildings ao set region = rg.name, regionid = rg.reg_gid
from (
 select s.gid, reg.gid as reg_gid, reg.name from addr.buildings s right join addr.regions reg on contains50(reg.geom, s.geom)
) rg
where ao.gid = rg.gid;

DO $$
    BEGIN
	RAISE INFO 'Прописали наименования региона, района, населенного пункта в osm.forts';
    END;
$$;
