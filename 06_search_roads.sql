-- таблица для поиска улиц

-- тебуются таблицы :
-- search_town_rn_rg
-- osm.roads
-- osm.water_line,
-- osm.water,
-- osm.square,
-- osm.parks,
-- osm.reserve_parks,
-- osm.forts,
-- osm.railway_point,
-- osm.island,
-- osm.cemetery
-- требуются функции:
-- t_polygon_is_contains(polygon geometry, some_geom geometry) returns boolean
-- t01_namenum_maker(condition text) returns void  ->  t01_namenumutils_create_uuid_string(arr uuid[], OUT result text) returns text
-- t01_getpoint(geom_list geometry[]) returns geometry

DROP TABLE if exists addr.search_town_rn_rg;

CREATE TABLE addr.search_town_rn_rg
(
    id         uuid NOT NULL DEFAULT uuid_generate_v4(),
    town_gid   uuid,
    town_v2_id bigint,
    town_name  character varying(256) COLLATE pg_catalog."default",
    rn_gid     uuid,
    rn_v2_id   bigint,
    rn_name    character varying(256) COLLATE pg_catalog."default",
    rg_gid     uuid,
    rg_v2_id   bigint,
    rg_name    character varying(256) COLLATE pg_catalog."default",
    town_geom  geometry,
    rn_geom    geometry,
    rg_geom    geometry,
    admin_lvl  int,
    CONSTRAINT search_town_rn_rg_pk PRIMARY KEY (id)
);
DROP INDEX IF EXISTS addr.searchtdr_town_geom, addr.searchtdr_rn_geom, addr.searchtdr_rg_geom;

CREATE INDEX searchtdr_town_geom ON addr.search_town_rn_rg USING GIST (town_geom);
CREATE INDEX searchtdr_rn_geom ON addr.search_town_rn_rg USING GIST (rn_geom);
CREATE INDEX searchtdr_rg_geom ON addr.search_town_rn_rg USING GIST (rg_geom);

DROP INDEX IF EXISTS
    addr.search_town_rn_rg_rg_gid_index, addr.search_town_rn_rg_rn_gid_index,
    addr.search_town_rn_rg_town_gid_index, addr.search_town_rn_rg_town_v2_id_index,
    addr.search_town_rn_rg_rn_v2_id_index, addr.search_town_rn_rg_rg_v2_id_index;

create index search_town_rn_rg_rg_gid_index on addr.search_town_rn_rg (rg_gid);
create index search_town_rn_rg_rn_gid_index on addr.search_town_rn_rg (rn_gid);
create index search_town_rn_rg_town_gid_index on addr.search_town_rn_rg (town_gid);
create index search_town_rn_rg_town_v2_id_index on addr.search_town_rn_rg (town_v2_id);
create index search_town_rn_rg_rn_v2_id_index on addr.search_town_rn_rg (rn_v2_id);
create index search_town_rn_rg_rg_v2_id_index on addr.search_town_rn_rg (rg_v2_id);

DO
$$
    begin
        raise notice 'сделал таблицу search_town_rn_rg';
    end
$$;

--сделаем из населённых пунктов лоскуты порезанные по райнам, т.к. например территория шувалово, озерки, выборгская сторона лежат в нескольких районах
WITH regions AS (
    SELECT reg.gid   as rg_gid,
           reg.geom  as rg_geom,
           reg.v2_id as rg_v2_id,
           reg.name  as rg_name
    FROM addr.regions reg
),
     raions AS (
         SELECT rn.gid   as rn_gid,
                rn.geom  as rn_geom,
                rn.v2_id as rn_v2_id,
                rn.name  as rn_name
         FROM addr.districts rn
     ),
     raions_with_regions AS (
         SELECT DISTINCT rn.*, rg.*
         FROM raions rn
                  LEFT JOIN regions rg ON t_polygon_is_contains(rg.rg_geom, rn.rn_geom)
     ),
     towns AS (
         SELECT gid                        AS town_gid,
                v2_id                      as town_v2_id,
		        /*t01_format_addr_city(city) AS town_name,*/
                t01_format_addr_city(name) AS town_name,
                geom_uniq                  AS town_geom,
                admin_level
         FROM addr.settlements
     ),
     raions_regions_towns AS (
         SELECT DISTINCT rn.*,
                         t.town_gid,
                         t.town_v2_id,
                         t.town_name,
                         t_intersection(t.town_geom, rn.rn_geom, 3) as town_geom,
                         t.admin_level                              as admin_lvl
         FROM raions_with_regions rn
                  LEFT JOIN towns t ON t_polygon_is_contains(rn.rn_geom, t.town_geom) or
                                       t_polygon_is_contains(t.town_geom, rn.rn_geom)
     )
insert
into addr.search_town_rn_rg(town_gid, town_v2_id, town_name, rn_gid, rn_v2_id, rn_name, rg_gid, rg_v2_id,
                            rg_name, town_geom, rn_geom,
                            rg_geom, admin_lvl)
SELECT town_gid,
       town_v2_id,
       town_name,
       rn_gid,
       rn_v2_id,
       rn_name,
       rg_gid,
       rg_v2_id,
       rg_name,
       town_geom,
       rn_geom,
       rg_geom,
       admin_lvl
FROM raions_regions_towns
UNION
SELECT null::uuid     as town_gid,
       null::bigint   as town_v2_id,
       null::text     as town_name,
       rn_gid,
       rn_v2_id,
       rn_name,
       rg_gid,
       rg_v2_id,
       rg_name,
       null::geometry as town_geom,
       rn_geom,
       rg_geom,
       null::int      as admin_lvl
FROM raions_with_regions
union
SELECT null::uuid     as town_gid,
       null::bigint   as town_v2_id,
       null::text     as town_name,
       null::uuid     as rn_gid,
       null::bigint   as rn_v2_id,
       null::text     as rn_name,
       rg_gid,
       rg_v2_id,
       rg_name,
       null::geometry as town_geom,
       null::geometry as rn_geom,
       rg_geom,
       null::int      as admin_lvl
FROM regions rn_rg;
DO
$$
    begin
        raise notice 'заполнил search_town_rn_rg';
    end
$$;


DROP TABLE if exists addr.search_roads;

CREATE TABLE addr.search_roads
(
    gid          uuid                                                NOT NULL DEFAULT uuid_generate_v4(),
    namenum      integer,
    namenum_v2   integer,
    old_namenum  bigint,
    name         character varying(256) COLLATE pg_catalog."default" NOT NULL,
    town_gid     uuid,
    town_v2_id   bigint,
    town_name    character varying(256) COLLATE pg_catalog."default",
    rn_gid       uuid,
    rn_v2_id     bigint,
    rn_name      character varying(256) COLLATE pg_catalog."default",
    rg_gid       uuid,
    rg_v2_id     bigint,
    rg_name      character varying(256) COLLATE pg_catalog."default",
    gids         uuid[],
    geom         geometry,
    center_point geometry,
    tipe         character varying(256) COLLATE pg_catalog."default",
    vector_text  text COLLATE pg_catalog."default",
    vec          tsvector,
    resp_zones   uuid[],
    CONSTRAINT search_roads_pk PRIMARY KEY (gid)
);

drop index if exists addr.search_roads_namenum_index, addr.search_roads_geom_index,
    addr.search_roads_vector_text_gin_index, addr.search_roads_name_index;

create index search_roads_namenum_index on addr.search_roads (namenum);
create index search_roads_geom_index on addr.search_roads using gist (geom);
-- create index search_roads_vector_text_gin_index on addr.search_roads using gin (vector_text gin_trgm_ops);
create index search_roads_name_index on addr.search_roads (name);

drop index if exists addr.search_roads_namenum_index, addr.search_roads_namenum_v2_index;

create index search_roads_namenum_index on addr.search_roads (namenum);
create index search_roads_namenum_v2_index on addr.search_roads (namenum_v2);

DROP INDEX IF EXISTS
    addr.search_roads_rg_gid_index, addr.search_roads_rn_gid_index,
    addr.search_roads_town_gid_index, addr.search_roads_town_v2_id_index,
    addr.search_roads_rn_v2_id_index, addr.search_roads_rg_v2_id_index;

create index search_roads_rg_gid_index on addr.search_roads (rg_gid);
create index search_roads_rn_gid_index on addr.search_roads (rn_gid);
create index search_roads_town_gid_index on addr.search_roads (town_gid);
create index search_roads_town_v2_id_index on addr.search_roads (town_v2_id);
create index search_roads_rn_v2_id_index on addr.search_roads (rn_v2_id);
create index search_roads_rg_v2_id_index on addr.search_roads (rg_v2_id);


DO
$$
    begin
        raise notice 'сделал таблицу search_roads';
    end
$$;

with roads1 as (
    select r.gid,
           name,
           'roads' as tipe,
           geom
    from addr.streets r
    where source = 'roads'
      and --highway not in ('proposed') and
        name is not null
),
     roads2 as (
         select r.gid,
                r.name,
                r.tipe,
                s.town_gid,
                s.town_v2_id,
                s.town_name,
                coalesce(s.rn_gid, rn.rn_gid)                                          as rn_gid,
                coalesce(s.rn_v2_id, rn.rn_v2_id)                                      as rn_v2_id,
                coalesce(s.rn_name, rn.rn_name)                                        as rn_name,
                coalesce(s.rg_gid, rn.rg_gid, rg.rg_gid)                               as rg_gid,
                coalesce(s.rg_v2_id, rn.rg_v2_id, rg.rg_v2_id)                         as rg_v2_id,
                coalesce(s.rg_name, rn.rg_name, rg.rg_name)                            as rg_name,
                st_intersection(r.geom, coalesce(s.town_geom, rn.rn_geom, rg.rg_geom)) as geom
         from roads1 r
                  left join addr.search_town_rn_rg s on t_polygon_is_contains(s.town_geom, r.geom)
                  left join addr.search_town_rn_rg rn
                            on s.town_gid is null and rn.town_gid is null and
                               t_polygon_is_contains(rn.rn_geom, r.geom)
                  left join addr.search_town_rn_rg rg on s.town_gid is null
             and rn.town_gid is null
             and rn.rn_gid is null
             and rg.town_gid is null
             and rg.rn_gid is null
             and t_polygon_is_contains(rg.rg_geom, r.geom)
     ),
     roads4 as (
         select name,
                tipe,
                town_gid,
                town_v2_id,
                town_name,
                rn_gid,
                rn_v2_id,
                rn_name,
                rg_gid,
                rg_v2_id,
                rg_name,
                array_agg(gid)                as gids,
                st_union(array_agg(geom))     as geom,
                t01_getpoint(array_agg(geom)) as center_point
         from roads2
         group by name, town_gid, town_v2_id, town_name, rn_gid, rn_v2_id, rn_name, rg_gid, rg_v2_id, rg_name,
                  tipe
     )
insert
into addr.search_roads(name, town_gid, town_v2_id, town_name, rn_gid, rn_v2_id, rn_name, rg_gid, rg_v2_id,
                       rg_name, gids, geom,
                       center_point, tipe)
select name,
       town_gid,
       town_v2_id,
       town_name,
       rn_gid,
       rn_v2_id,
       rn_name,
       rg_gid,
       rg_v2_id,
       rg_name,
       gids,
       geom,
       center_point,
       tipe
from roads4;

DO
$$
    begin
        raise notice 'заполнил search_roads';
    end
$$;

--          добавление highways
with high as (
    select gid, name, geom, 'highway' as tipe
    from addr.streets
    where name != 'ЗСД'
      and name != 'КАД'
      and name != '«Нева»'
      and source = 'highways'
)
insert
into addr.search_roads(name, gids, geom,
                       center_point, tipe, vector_text)
select name,
       array_agg(gid)                as gids,
       st_union(array_agg(geom))     as geom,
       t01_getpoint(array_agg(geom)) as center_point,
       tipe,
       lower(name)                   as vector_text
from high
group by name, tipe;

------------------


--нас. пункты как улицы
insert into addr.search_roads(name, town_gid, town_v2_id, town_name, rn_gid, rn_v2_id, rn_name, rg_gid,
                              rg_v2_id, rg_name, gids, geom,
                              center_point, tipe)
select distinct town_name,
                town_gid,
                town_v2_id,
                town_name,
                rn_gid,
                rn_v2_id,
                rn_name,
                rg_gid,
                rg_v2_id,
                rg_name,
                array [town_gid],
                town_geom,
                st_centroid(town_geom),
                'town'
from addr.search_town_rn_rg
where town_gid is not null
  and town_name is not null
  and admin_lvl > 10;

--недоулицы
with pseudoStreets1 as (
    select gid,
           case source
               when 'water' then (name || ' (водоём)'::text)
               when 'water_line' then (name || ' (водоём)'::text)
               when 'railway_point' then ('ж/д станция: '::text || name)
               when 'cemetery' then CASE
                                        WHEN (lower(name) ~ similar_escape('%(кладбище)%'::text, NULL::text)) THEN name
                                        ELSE (name || ' (кладбище)'::text)
                   END
               else name
               end as name,
           geom,
           case source
               when 'water' then 'water'
               when 'water_line' then 'water'
               else source
               end as tipe
    from addr.addrobj
    where source <> 'milestone_point'
),
     pseudoStreets2 as (
         select w.tipe,
                w.gid,
                w.name,
                s.town_gid,
                s.town_v2_id,
                s.town_name,
                coalesce(s.rn_gid, rn.rn_gid)                                          as rn_gid,
                coalesce(s.rn_v2_id, rn.rn_v2_id)                                      as rn_v2_id,
                coalesce(s.rn_name, rn.rn_name)                                        as rn_name,
                coalesce(s.rg_gid, rn.rg_gid, rg.rg_gid)                               as rg_gid,
                coalesce(s.rg_v2_id, rn.rg_v2_id, rg.rg_v2_id)                         as rg_v2_id,
                coalesce(s.rg_name, rn.rg_name, rg.rg_name)                            as rg_name,
                st_intersection(w.geom, coalesce(s.town_geom, rn.rn_geom, rg.rg_geom)) as geom
         from pseudoStreets1 w
                  left join addr.search_town_rn_rg s on t_polygon_is_contains(s.town_geom, w.geom)
                  left join addr.search_town_rn_rg rn
                            on s.town_gid is null and rn.town_gid is null and
                               t_polygon_is_contains(rn.rn_geom, w.geom)
                  left join addr.search_town_rn_rg rg on s.town_gid is null
             and rn.town_gid is null
             and rn.rn_gid is null
             and rg.town_gid is null
             and rg.rn_gid is null
             and t_polygon_is_contains(rg.rg_geom, w.geom)
         where w.name is not null
     ),
     pseudoStreets3 as (
         select tipe,
                name,
                town_gid,
                town_v2_id,
                town_name,
                rn_gid,
                rn_v2_id,
                rn_name,
                rg_gid,
                rg_v2_id,
                rg_name,
                array_agg(gid)                as gids,
                st_union(array_agg(geom))     as geom,
                t01_getpoint(array_agg(geom)) as center_point
         from pseudoStreets2
         group by name, town_gid, town_v2_id, town_name, rn_gid, rn_v2_id, rn_name, rg_gid, rg_v2_id, rg_name,
                  tipe
     )
insert
into addr.search_roads(name, town_gid, town_v2_id, town_name, rn_gid, rn_v2_id, rn_name, rg_gid, rg_v2_id,
                       rg_name, gids, geom,
                       center_point, tipe)
select name,
       town_gid,
       town_v2_id,
       town_name,
       rn_gid,
       rn_v2_id,
       rn_name,
       rg_gid,
       rg_v2_id,
       rg_name,
       gids,
       geom,
       center_point,
       tipe
from pseudoStreets3;


-- отдельно заполняю namenum
DO
$$
    begin
        raise notice 'заполняю namenum';
        perform t01_namenum_maker(null);
        raise notice 'готово';
    end
$$;

update addr.buildings bi
set namenum=nn.namenum
from (
         with roads as (
             select distinct namenum, town_name, name as str_name, geom
             from addr.search_roads
         )
         select b.gid, roads.namenum
         from addr.buildings as b
                  inner join roads on roads.str_name = b.street and ST_DWithin(b.geom, roads.geom, 1500)
     ) nn
where bi.gid = nn.gid;


update addr.search_roads
set geom = st_linemerge(geom)
where geometrytype(geom) in ('MULTILINESTRING');

update addr.search_roads
set vector_text = lower(coalesce(name, '')) || ' ' || lower(coalesce(town_name, '')) || ' ' ||
                  lower(coalesce(rn_name, '')) || ' ' || lower(coalesce(rg_name, ''))
where true;


alter table addr.search_roads add column if not exists old_gid uuid;
alter table addr.search_roads add column if not exists prev_namenum integer;
update addr.search_roads set old_gid = null, prev_namenum = null;
with uniq as (
	select n.rg_gid, n.rn_gid, n.town_gid, n.name, count(*) from addr_old.search_roads n
	group by 1,2,3,4
	having count(*) = 1
), comp as (
	select o.gid as old_gid, o.namenum as old_namenum, n.gid from addr.search_roads n
	join addr_old.search_roads o on (n.rg_gid = o.rg_gid and n.rn_gid = o.rn_gid and n.town_gid = o.town_gid and n.name = o.name and n.tipe = o.tipe)
	where exists (
		select * from uniq
		where uniq.rg_gid = o.rg_gid and uniq.rn_gid = o.rn_gid and uniq.town_gid = o.town_gid and uniq.name = o.name
	)
)
update addr.search_roads sr set old_gid = comp.old_gid, prev_namenum = comp.old_namenum
from comp where comp.gid = sr.gid;