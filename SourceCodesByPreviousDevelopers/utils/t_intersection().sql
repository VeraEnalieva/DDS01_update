CREATE OR REPLACE function t_intersection(geom1 geometry, geom2 geometry, tipe integer) returns geometry
    language plpgsql
as
$$
    --находит пересечение геометрий, и если результат GEOMETRYCOLLECTION извлекает указаный тип 1 == POINT, 2 == LINESTRING, 3 == POLYGON
declare
    res geometry;
    geom_type varchar(256);
begin
    res := st_intersection(geom1, geom2);
    geom_type := geometrytype(res);
    if geom_type = 'GEOMETRYCOLLECTION'
    then res := ST_MULTI(ST_CollectionExtract(res, tipe));
    end if;
    return res;
exception when others then return false;

end;

$$;

alter function t_intersection(geometry, geometry, integer) owner to postgres;

