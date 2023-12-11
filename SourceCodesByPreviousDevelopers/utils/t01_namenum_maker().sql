CREATE OR REPLACE function t01_namenum_maker(condition text) returns void
    language plpgsql
as
$$
declare
    gids       uuid[];
    elem       uuid;
    neig       uuid[];
    temp_neig  uuid[];
    rand_value int;
    nanenum int := 1;
begin

    select coalesce(max(namenum),1) from addr.search_roads into nanenum;

    if condition is not null then
        condition := 'and ' || condition;
    else
        condition := '';
    end if;
    execute 'select array_agg(gid) from addr.search_roads where namenum is null ' || condition into gids;

    while array_length(gids, 1) > 0
        loop
            elem := gids[1];
            neig := array_append(neig, elem);
            temp_neig := array_append(temp_neig, elem);

            while temp_neig is not null and array_length(temp_neig, 1) > 0
                loop
                    -- поиск соседей для элементов neig
                    execute 'with temp as(select name, geom, tipe from addr.search_roads where gid in (' ||
                            t01_namenumutils_create_uuid_string(temp_neig) || '))
                    select array_agg(distinct r.gid) from addr.search_roads r inner join temp on (r.gid not in (' ||
                            t01_namenumutils_create_uuid_string(neig) ||
                            ') and r.name ilike temp.name and r.tipe = temp.tipe and st_distance(temp.geom, r.geom) < 500)'
                        into temp_neig;
                    if temp_neig is not null then
                        neig := array_cat(neig, temp_neig);
                    end if;
                end loop;
            -- namenum setting
            rand_value := nanenum;
            nanenum := nanenum +1;
            execute 'update addr.search_roads set namenum = $1 where gid in (' ||
                    t01_namenumutils_create_uuid_string(neig) || ')' using rand_value;

            -- deleting temp arrays
            while array_length(neig, 1) > 0
                loop
                    gids := array_remove(gids, neig[1]);
                    neig := array_remove(neig, neig[1]);
                end loop;
        end loop;
end
$$;

alter function t01_namenum_maker(text) owner to postgres;

