select blocked.pid as blocked_pid,
       blocked.usename as blocked_user,
       blocking.pid as blocking_pid,
       blocking.usename as blocking_user,
       now() - blocked.query_start as waiting,
       left(blocked.query, 120) as blocked_query,
       left(blocking.query, 120) as blocking_query
from pg_stat_activity blocked
cross join lateral unnest(pg_blocking_pids(blocked.pid)) as b(pid)
join pg_stat_activity blocking on blocking.pid = b.pid
order by waiting desc;
