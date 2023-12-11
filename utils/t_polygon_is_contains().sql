--проверяет можно ли считать что полигон содержит какую-либо геометрию.
-- учитывается длина входящего куска дороги, процент площади полигона....

CREATE OR REPLACE function t_polygon_is_contains(polygon geometry, some_geom geometry) returns boolean
    language plpgsql
as
$$
declare
    res boolean := false;
    lmt float4 :=0.025;
    some_geom_type varchar(256);
begin
    some_geom_type := geometrytype(some_geom);
    if some_geom_type = 'GEOMETRYCOLLECTION'
    then some_geom := ST_MULTI(ST_CollectionExtract(some_geom, 3));
    end if;
    res := st_intersects(polygon, some_geom) and (st_contains(polygon, some_geom) or st_contains(some_geom, polygon)
        or (some_geom_type in ('LINESTRING','MULTILINESTRING') and st_length(st_intersection(some_geom, polygon)) > 5)
        or (some_geom_type in ('POLYGON','MULTIPOLYGON')  and st_area(st_intersection(some_geom,polygon)) / st_area(some_geom) > lmt)
        );
    return res;
exception when others then return false;

end;

$$;

alter function t_polygon_is_contains(geometry, geometry) owner to postgres;

