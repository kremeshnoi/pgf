select a.attnum as position,
       a.attname as "column",
       format_type(a.atttypid, a.atttypmod) as type,
       not a.attnotnull as nullable,
       pg_get_expr(d.adbin, d.adrelid) as "default"
from pg_attribute a
left join pg_attrdef d on d.adrelid = a.attrelid and d.adnum = a.attnum
where a.attrelid = to_regclass(:'table')
  and a.attnum > 0
  and not a.attisdropped
order by a.attnum;
