do
$$
    declare
        r1                record;
        r2                record;
        rgid              uuid;
        rnid              uuid;
        distrTableEdges   text;
        distrTableNodes   text;
        geo               geometry;
        totalGeo          geometry;
        distrNodeId       integer;
        distr_interNodeId integer;
        interNodeId       integer;
    begin
        alter table departments
            add column if not exists distr_tabl_distr_id integer; -- id ближайшей точки из distr table
        alter table departments
            add column if not exists distr_tabl_inter_id integer; -- id ближайшей точки из distr table, которая совпадает с точкой из inter table
        alter table departments
            add column if not exists inter_table_id integer; -- id ближайшей точки из inter table
        alter table departments
            add column if not exists inter_street_path geometry;
        alter table departments
            add column if not exists district_street_path geometry;

        alter table departments
            add column if not exists point geometry;
        update departments
        set point=st_transform(st_setsrid(st_makepoint("addressLocationX", "addressLocationY"), 4326), 3857);

        for r1 in select id, point
                  from departments
                  where point is not null
            loop
                --                         определяю район/регион и заношу в таблицу
                raise notice 'for %', r1.id;
                for r2 in select * from osm.regions where admin_level = 4 and st_contains(geom, r1.point)
                    loop
                        raise notice 'rg_id %', r2.gid;
                        rgid := r2.gid;
                    end loop;
                for r2 in select * from osm.regions where admin_level in (5, 6) and st_contains(geom, r1.point)
                    loop
                        raise notice 'rn_id %', r2.gid;
                        rnid := r2.gid;
                    end loop;
                distrTableEdges := 'routing.distr_roads_' || substring(rgid::text from 1 for 8) || '_' ||
                                   substring(rnid::text from 1 for 8) || '_noded';
                distrTableNodes := distrTableEdges || '_vertices_pgr';
                raise notice '%', distrTableNodes;
                update departments set "addressRegionId"=rgid, "addressDistrictId"=rnid where id = r1.id;
                --                 raise notice '!!!!!!!!';
-- --                     нахожу id ближайшей точки района(для пч) и рисую путь от пч к ней
                execute 'with t as (select * from ' || distrTableNodes || '),
                    f as (select * from departments f where id=''' || r1.id || ''')
                    select st_makeline(t.the_geom, f.point), t.id from t inner join f on true
                    ORDER BY ST_Distance(t.the_geom, f.point)
                    limit 1' into geo, distrNodeId;
                totalGeo := geo;
                update departments
                set district_street_path=geo,
                    distr_tabl_distr_id=distrNodeId
                where id = r1.id;

-- --                 получаю ближайшую магистральную точку к пч и строю маршрут(пч-точка района + точка района-точка магистрали)
                execute 'with intersected as (select i.id inter_table_id, i.the_geom inter_geom, d.id distr_tabl_inter_id
                                     from routing.distr_roads0_inter_noded_vertices_pgr i
                                              inner join ' || distrTableNodes || ' d
                                     on i.the_geom && d.the_geom),
                     point as (select * from ' || distrTableNodes || ' where id=' || distrNodeId || ')
                select intersected.inter_table_id,
                       intersected.distr_tabl_inter_id
                from intersected,
                     point
                ORDER BY ST_Distance(intersected.inter_geom, point.the_geom)
                limit 1' into interNodeId, distr_interNodeId;

                update departments
                set inter_table_id=interNodeId,
                    distr_tabl_inter_id=distr_interNodeId
                where id = r1.id;

                if distrNodeId != distr_interNodeId then -- если ближ точка района и магистральная - не одна и та же
                    select path into geo from t01_dijkstra_wrapper(distrTableEdges, distrNodeId, distr_interNodeId);
                    totalGeo := st_union(totalGeo, geo); -- геометрия маршрута от пч до межрайонной дороги
                end if;

                update departments
                set inter_street_path=totalGeo
                where id = r1.id;
            end loop;
    end;
$$;