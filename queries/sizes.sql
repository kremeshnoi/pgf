select current_database() as database,
       pg_size_pretty(pg_database_size(current_database())) as size;

select n.nspname as schema,
       c.relname as "table",
       pg_size_pretty(pg_total_relation_size(c.oid)) as total,
       pg_size_pretty(pg_relation_size(c.oid)) as data,
       pg_size_pretty(pg_indexes_size(c.oid)) as indexes
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where c.relkind in ('r', 'p', 'm')
  and n.nspname not in ('pg_catalog', 'information_schema')
  and n.nspname not like 'pg_toast%'
order by pg_total_relation_size(c.oid) desc
limit 30;
