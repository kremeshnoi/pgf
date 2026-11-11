select pid,
       usename as "user",
       datname as database,
       state,
       now() - query_start as duration,
       wait_event_type,
       wait_event,
       left(query, 200) as query
from pg_stat_activity
where state <> 'idle'
  and pid <> pg_backend_pid()
order by query_start;
