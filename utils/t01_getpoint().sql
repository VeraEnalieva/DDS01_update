
-- принимает массив геометрий кусков улицы
-- возвращает геометрию точки, примерный центр для этого массива
CREATE OR REPLACE function t01_getpoint(geom_list geometry[]) returns geometry
    language plpgsql
as
$$
declare

    max_geom geometry := geom_list[1];
    max_type text;
    i        geometry;

begin

    foreach i in array geom_list

        loop

            if st_length(st_longestline(i, i)) > st_length(st_longestline(max_geom, max_geom))
            then
                max_geom := i;
            end if;


        end loop;

    max_type = geometrytype(max_geom);

    if max_type = 'LINESTRING'
    then
        max_geom := st_lineinterpolatepoint(max_geom, 0.5);
    elseif max_type = 'MULTILINESTRING'
    then
        i = st_linemerge(max_geom);
        if geometrytype(i) = 'LINESTRING'
        then
            max_geom := st_lineinterpolatepoint(st_linemerge(max_geom), 0.5);
        else
            if st_distance(max_geom, st_centroid(max_geom)) < 1
            then
                max_geom := st_centroid(max_geom);
            else
                max_geom := st_pointonsurface(max_geom);
            end if;
        end if;
    elseif max_type in ('POLYGON', 'MULTIPOLYGON')
    then
        if st_contains(max_geom, st_centroid(max_geom))
        then
            max_geom := st_centroid(max_geom);
        else
            max_geom := st_pointonsurface(max_geom);
        end if;
    else
        max_geom := st_pointonsurface(max_geom);
    end if;


    return max_geom;

end;

$$;

alter function t01_getpoint(geometry[]) owner to postgres;

