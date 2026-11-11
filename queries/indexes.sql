select schemaname as schema,
       tablename as "table",
       indexname as "index",
       pg_size_pretty(pg_relation_size(format('%I.%I', schemaname, indexname)::regclass)) as size,
       indexdef as definition
from pg_indexes
where schemaname not in ('pg_catalog', 'information_schema')
order by schemaname, tablename, indexname;
