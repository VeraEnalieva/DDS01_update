CREATE OR REPLACE function t01_namenumutils_create_uuid_string(arr uuid[], OUT result text) returns text
    language plpgsql
as
$$
declare
    iter integer;
begin
    result := '''';
    for iter in 1..array_length(arr, 1)
        loop
            if iter < array_length(arr, 1) then
                result := concat(result, arr[iter], ''', ''');
            else
                result := concat(result, arr[iter], '''');
            end if;
        end loop;
end;
$$;

alter function t01_namenumutils_create_uuid_string(uuid[], out text) owner to postgres;

