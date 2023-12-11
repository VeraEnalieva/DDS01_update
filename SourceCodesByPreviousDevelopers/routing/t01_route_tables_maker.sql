-- FUNCTION: public.t01_route_tables_maker()

-- DROP FUNCTION IF EXISTS public.t01_route_tables_maker();

CREATE OR REPLACE FUNCTION public.t01_route_tables_maker(
	)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
    rg                           record;
    rec                          record;
    tempTableName                text;
    tempTableName_noded          text;
    tempTableName_noded_vertices text;
    debugCounter                 integer := 0;
    accumEdgesCounter            integer := 0;
    accumNodesCounter            integer := 0;
begin

raise notice 'cleaned routing schema';
	 
	
     drop table if exists routing.allroads;
--         временная таблица, на основе которой будут строиться таблицы для районов
     create table routing.allroads
     (
         gid          uuid,
         name         text,
         rg_id        uuid,
         rn_id        uuid,
         the_geom     geometry,
         highway      text,
         oneway       text,
         surface      text,
         maxspeed     text,
         maxspeed_int integer
     );
     insert into routing.allroads (gid, name, the_geom, highway, oneway, surface, maxspeed)
         (
             select gid, name, ST_LineMerge(r.geom), highway, oneway, surface, maxspeed
             from osm.roads r
             where r.highway in
                   ('trunk', 'motorway', 'primary', 'secondary', 'tertiary', 'unclassified', 'residential',
                    'primary_link', 'secondary_link', 'tertiary_link', 'motorway_link', 'service')
         );
     raise notice 'temp table completed';

     execute t01_set_maxspeed('routing.allroads');

--     заполнение района-региона
     perform t01_set_rn_or_rg_ids_for_allroads('rg_id');
     perform t01_set_rn_or_rg_ids_for_allroads('rn_id');

    ------------------------------------------------------------------------------------------
    -- making interdistrict table
    ------------------------------------------------------------------------------------------
    --                 временная таблица для подготовки highways(считаю cost)
	drop table if exists routing.highways_temp;
    create table routing.highways_temp
    (
        gid          uuid,
        name         text,
        the_geom     geometry,
        highway      text,
        oneway       text,
        maxspeed     text,
        maxspeed_int integer,
        cost         double precision,
        reverse_cost double precision
    );
    insert into routing.highways_temp (gid, name, the_geom, highway, oneway, maxspeed, maxspeed_int)
        (
            select gid, name, geom, highway, oneway, maxspeed, maxspeed_int
            from osm.highways
        );
    execute t01_set_maxspeed('routing.highways_temp');
    raise notice 'maxspeed setted';

    --         делаю межрайонную таблицу
	drop table if exists routing.distr_roads0_inter;
    create table routing.distr_roads0_inter
    (
        id           serial,
        gid          uuid,
        name         text,
        cost         double precision,
        reverse_cost double precision,
        the_geom     geometry,
        highway      text,
        oneway       text,
        maxspeed     integer
    );
    insert into routing.distr_roads0_inter (gid, name, the_geom, highway, oneway, maxspeed)
        (
            select gid, name, ST_LineMerge(r.the_geom), highway, oneway, maxspeed
            from routing.allroads r
            where r.highway not in ('residential', 'unclassified', 'service', 'tertiary_link')
            union
            select gid, name, ST_LineMerge(h.the_geom), highway, oneway, maxspeed
            from routing.highways_temp h
        );
    drop table routing.highways_temp;
    raise notice 'interroad created';
--                 делаю edges
    perform pgr_nodeNetwork('routing.distr_roads0_inter', 0.001);
    raise notice 'nodenetwork done';
--                 делаю nodes
    perform pgr_createTopology('routing.distr_roads0_inter_noded', 0.001);
    raise notice 'createtopology done';
    perform pgr_analyzegraph('routing.distr_roads0_inter_noded', 0.001);
    raise notice 'analyzegraph done';
--             таблица для проблемных линий
	drop table if exists routing.distr_temp;
    create table routing.distr_temp
    (
        id       serial,
        edg_id   integer,
        vert_id  integer,
        old_id   integer,
        the_geom geometry
    );
    raise notice 'таблица для проблемных линий done';
--             разбиваю те линии, которые не разделил pgr_nodeNetwork,
    execute 'insert into routing.distr_temp (edg_id, vert_id, old_id, the_geom)
            (
                with v as (select *
                           from routing.distr_roads0_inter_noded_vertices_pgr
                           where chk = 1),
                     e as (select ee.id, ee.the_geom, ee.old_id
                           from routing.distr_roads0_inter_noded ee,
                                v
                           where st_intersects(ee.the_geom, v.the_geom)
                             and st_contains(ee.the_geom, v.the_geom))
                select e.id, v.id, e.old_id, (st_dump(st_split(e.the_geom, v.the_geom))).geom
                from v
                         inner join e on st_intersects(e.the_geom, v.the_geom)
            );';
    raise notice 'разбил проблемные и записал в distr_temp done';
--             записываю в изначальную таблицу, сразу же удаляя старые неправильные
    for rec in
        select distinct edg_id
        from routing.distr_temp
        loop
            execute 'insert into routing.distr_roads0_inter_noded (old_id, the_geom)
                    (
                        select old_id, the_geom from routing.distr_temp where edg_id = ' || rec.edg_id || '
                    );';
            execute 'delete from routing.distr_roads0_inter_noded where id = ' || rec.edg_id || ';';
        end loop;
    raise notice 'обновил начальную табл  done';
    --   тут скорее всего будет лучше не строить заново топологию, а просто расчитать source&target отдельно
--   для каждой линии. Для этого нужно знать, какие направления и source&target соответствуют
--             каждому из кусков дороги, а тут проблемы
    drop table routing.distr_temp;
    drop table routing.distr_roads0_inter_noded_vertices_pgr;
    update routing.distr_roads0_inter_noded set source=null, target=null where true;
    raise notice 'делаю топологию заново';
    perform pgr_createTopology('routing.distr_roads0_inter_noded', 0.001);
    raise notice 'сделал топологию';
    --                 добавляю и заполняю столбцы в таблицах edges&nodes
--                 и сразу обновляю значения accumEdgesCounter, accumNodesCounter

    select accedges, accnodes
    into accumEdgesCounter, accumNodesCounter
    from t01_format_table('routing.distr_roads0_inter', accumEdgesCounter, accumNodesCounter);
    raise notice 't01_format_table';
--             заполняю веса дорог
    execute 'update routing.distr_roads0_inter_noded
        set cost         = st_length(the_geom) / maxspeed,
            reverse_cost = st_length(the_geom) / maxspeed
        where oneway is null
           or oneway in (''no'', ''reversible'');';
    execute 'update routing.distr_roads0_inter_noded set cost=st_length(the_geom) / maxspeed, reverse_cost=1000000 where oneway = ''yes'';';
    raise notice 'costs done';
--         удаление временных
    drop table routing.distr_roads0_inter;
    execute 'create index routing_distr_roads0_inter_noded_source_index on routing.distr_roads0_inter_noded(source)';
    execute 'create index routing_distr_roads0_inter_noded_target_index on routing.distr_roads0_inter_noded(target)';
    execute 'create index routing_distr_roads0_inter_vertices_id_index on routing.distr_roads0_inter_noded_vertices_pgr(id)';
    -- ------------------------------------------------------------------------------------------
    -- making district tables
    ------------------------------------------------------------------------------------------
    --             здесь создаем таблицы районов. их количество равно количеству уникальных пар rg_id, rn_id
    for rg in select distinct rg_id, rn_id
              from routing.allroads
        loop
            raise notice '_____% STARTS', debugCounter;
            tempTableName := 'routing.distr_roads_' || substring(rg.rg_id::text from 1 for 8) || '_' ||
                             substring(rg.rn_id::text from 1 for 8);
            tempTableName_noded := tempTableName || '_noded';
            tempTableName_noded_vertices := tempTableName_noded || '_vertices_pgr';

			execute 'drop table if exists ' || tempTableName || ';';
            execute 'create table ' || tempTableName || '
            (
                id       serial,
                gid      uuid,
                name     text,
                highway text,
                oneway text,
                maxspeed integer,
                the_geom geometry
            );';

            execute 'insert into ' || tempTableName || ' (gid, name, highway, the_geom, oneway, maxspeed)
            select gid, name, highway, ST_LineMerge(the_geom), oneway, maxspeed
            from routing.allroads
            where rg_id = ''' || rg.rg_id || '''
              and rn_id = ''' || rg.rn_id || ''';
            ';
            raise notice '_____% created&inserted',tempTableName;

            --                 делаю edges
--         raise notice '_____pgr_nodeNetwork starting..';
            perform pgr_nodeNetwork(tempTableName, 0.001);
            --         raise notice '_____pgr_nodeNetwork ended';
--
-- --                 делаю nodes
--         raise notice 'pgr_createTopology starting..';
            perform pgr_createTopology(tempTableName_noded, 0.001);
            --         raise notice 'pgr_createTopology ended';

--             ищу ошибки в графе, которые дальше буду исправлять
            perform pgr_analyzegraph(tempTableName_noded, 0.001);

--             таблица для проблемных линий
			drop table if exists routing.distr_temp;
            create table routing.distr_temp
            (
                id       serial,
                edg_id   integer,
                vert_id  integer,
                old_id   integer,
                the_geom geometry
            );
--             разбиваю те линии, которые не разделил pgr_nodeNetwork,
            execute 'insert into routing.distr_temp (edg_id, vert_id, old_id, the_geom)
            (
                with v as (select *
                           from ' || tempTableName_noded_vertices || '
                           where chk = 1),
                     e as (select ee.id, ee.the_geom, ee.old_id
                           from ' || tempTableName_noded || ' ee,
                                v
                           where st_intersects(ee.the_geom, v.the_geom)
                             and st_contains(ee.the_geom, v.the_geom))
                select e.id, v.id, e.old_id, (st_dump(st_split(e.the_geom, v.the_geom))).geom
                from v
                         inner join e on st_intersects(e.the_geom, v.the_geom)
            );';
            --                 исправленные линии нужно вставить в изначальную таблицу _noded. Но удалить старые нельзя, тк собьется нумерация
--                 поэтому в функцию, считающую сдвиг в качестве начального id передаю количество записей в предыдущей таблице + количество исправленных линий
--                 Например, если в старой таблице 10 записей, 2 из них нужно разделить (получится 4 линии), то нумерацию след таблицы я начну с 10+4= с 14 номера
--                 с узлами такой проблемы нет, т.к. они не изменяются
--             записываю в изначальную таблицу, сразу же удаляя старые неправильные
            for rec in
                select distinct edg_id
                from routing.distr_temp
                loop
                    execute 'insert into ' || tempTableName_noded || ' (old_id, the_geom)
                    (
                        select old_id, the_geom from routing.distr_temp where edg_id = ' || rec.edg_id || '
                    );';
                    execute 'delete from ' || tempTableName_noded || ' where id = ' || rec.edg_id || ';';
                end loop;

            --             тут скорее всего будет лучше не строить заново топологию, а просто расчитать source&target отдельно
--                 для каждой линии.Для этого нужно знать, какbе направлениz и source&target соответствуют
--                 каждому из кусков дороги, а тут проблемы
            drop table routing.distr_temp;
            execute 'drop table ' || tempTableName_noded_vertices;
            execute 'update ' || tempTableName_noded || ' set source=null, target=null where true';

            perform pgr_createTopology(tempTableName_noded, 0.001);

            --                 добавляю и заполняю столбцы в таблицах edges&nodes
--                 и сразу обновляю значения accumEdgesCounter, accumNodesCounter
            select accedges, accnodes
            into accumEdgesCounter, accumNodesCounter
            from t01_format_table(tempTableName, accumEdgesCounter, accumNodesCounter);

            execute 'create index ' || replace(tempTableName, '.', '_') || '_source_index on ' || tempTableName_noded ||
                    '(source)';
            execute 'create index ' || replace(tempTableName, '.', '_') || '_target_index on ' || tempTableName_noded ||
                    '(target)';
            execute 'create index ' || replace(tempTableName, '.', '_') ||
                    'vertices_id_index on ' || tempTableName_noded || '_vertices_pgr(id)';
--             заполняю веса дорог
            execute '        update ' || tempTableName_noded || '
        set cost         = st_length(the_geom) / maxspeed,
            reverse_cost = st_length(the_geom) / maxspeed
        where oneway is null
           or oneway in (''no'', ''reversible'');';
            execute '        update ' || tempTableName_noded ||
                    ' set cost=st_length(the_geom) / maxspeed, reverse_cost=1000000 where oneway = ''yes'';';

            execute '
            DROP TABLE ' || tempTableName;
            raise notice ' district table % done ',tempTableName;
            raise notice '---------------';

            debugCounter := debugCounter + 1;
        end loop;

--         drop table routing.allroads;
end;
$BODY$;

ALTER FUNCTION public.t01_route_tables_maker()
    OWNER TO postgres;
