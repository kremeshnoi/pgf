# pgf

**Pick a Postgres connection, pick a saved query, run it — all from fzf.**

pgf is a small bash wrapper around the official `psql` client. Connections are plain libpq service files, queries are plain `.sql` files, and fzf glues them together with live previews. It runs the same on Linux and macOS.

```
$ pgf q
connection> prod                     │ from ~/.config/pgf/connections/work.conf
  prod-api                           │
  prod-billing                       │ host=db.example.com
  staging                            │ port=5432
  local                              │ dbname=api
                                     │ user=readonly

query> col                           │ asks for: table
  columns                            │
  active-queries                     │ select a.attnum as position,
  indexes                            │        a.attname as "column",
                                     │        ...
table: users
 position | column     | type                     | nullable | default
----------+------------+--------------------------+----------+---------------------------
        1 | id         | integer                  | f        | nextval('users_id_seq'...)
        2 | email      | text                     | f        |
```

## Features

- **No new config format.** Connections are [libpq service files](https://www.postgresql.org/docs/current/libpq-pgservice.html), the same ones `psql service=<name>` reads. Anything that speaks libpq can share them.
- **Connections from anywhere.** pgf collects them from the project you are in, from a folder of `*.conf` files and from `~/.pg_service.conf`, and shows them as one list.
- **Saved queries.** A starter set ships with pgf; your own `.sql` files sit next to it and override it by name.
- **Prompts for variables.** A query with `:'table'` in it asks `table:` before it runs and passes the answer to psql as a variable, quoted properly.
- **Passwords stay hidden.** The preview shows every key of a connection except `password`.
- **Nix-first, Nix-optional.** The flake brings psql, fzf, pspg and GNU tools along; without Nix it is one bash script.

## Usage

| Command | What it does |
|---|---|
| `pgf` | pick a connection, open `psql` |
| `pgf <service>` | open `psql` for that connection |
| `pgf q [service] [query]` | pick a connection and a query, run it; either argument skips its picker |
| `pgf ls` | list the saved queries |
| `pgf services` | list the connections and the file each one comes from |
| `pgf edit [query]` | edit a query in `~/.config/pgf/queries`, copying a built-in one there first |
| `pgf --help` | the same, in the terminal |

Pressing `Esc` in a picker exits quietly.

## Connections

A connection is a section in a service file:

```ini
[prod-api]
host=db.example.com
port=5432
dbname=api
user=readonly
sslmode=require
```

pgf reads service files from these places, in this order. When two files define the same name, the first one wins:

| Where | Use it for |
|---|---|
| `.pg_service.conf` in the current directory or any parent | the databases of the project you are in |
| `~/.config/pgf/connections/*.conf` | one file per client, team or environment |
| `~/.pg_service.conf` (or `$PGSERVICEFILE`) | the standard libpq location |
| `$PGSYSCONFDIR/pg_service.conf` | a system-wide file, when that variable is set |

When it starts `psql`, pgf points `PGSERVICEFILE` at the file the chosen connection came from, so every location works with stock `psql`.

Passwords can go into the service file as `password=...`, but [`~/.pgpass`](https://www.postgresql.org/docs/current/libpq-pgpass.html) keeps them out of it, and a project `.pg_service.conf` with passwords belongs in `.gitignore`.

## Queries

| Query | Shows |
|---|---|
| `tables` | every table with its schema, estimated rows and total size |
| `columns` | the columns of one table: type, nullability, default; asks for `table` |
| `indexes` | every index with its table, size and definition |
| `sizes` | the database size and the 30 largest tables, split into data and indexes |
| `active-queries` | what is running right now, longest first |
| `locks` | who is blocked and by whom |

Your own queries go into `~/.config/pgf/queries/<name>.sql`. A file there with the name of a built-in query replaces it, so `pgf edit tables` gives you your own copy of `tables` to change.

Variables use psql's own syntax: `:'name'` is substituted as a quoted literal, `:"name"` as a quoted identifier. pgf finds both, asks for each once, and runs the file with `psql -v name=value -f <file>`:

```sql
select *
from orders
where customer_id = :'customer'
order by created_at desc
limit 20;
```

Output goes through `$PSQL_PAGER`; the Nix package sets it to [pspg](https://github.com/okbob/pspg) unless you already have one.

## Install

### Nix flake with home-manager

```nix
{
  inputs.pgf = {
    url = "github:kremeshnoi/pgf";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

```nix
{
  imports = [ inputs.pgf.homeManagerModules.default ];

  programs.pgf = {
    enable = true;
    connections.work = ./pg/work.conf;
    queries.slow-queries = ./sql/slow-queries.sql;
  };
}
```

`connections` and `queries` land in `~/.config/pgf`. Files from the Nix store are world-readable, so keep passwords out of `connections` and put them in `~/.pgpass` or a secret manager such as sops-nix.

### Nix without home-manager

```bash
nix profile install github:kremeshnoi/pgf
nix run github:kremeshnoi/pgf -- q
```

### Without Nix

pgf needs bash 4 or newer, `psql` and `fzf`; `pspg` and `bat` are optional.

```bash
brew install bash libpq fzf pspg      # macOS
sudo apt install postgresql-client fzf pspg   # Debian, Ubuntu

git clone https://github.com/kremeshnoi/pgf ~/.local/share/pgf
```

Then put `~/.local/share/pgf/bin` on your `PATH`. The script finds the built-in queries in `../queries` next to itself, or wherever `PGF_BUILTIN_QUERIES` points.

## Environment

| Variable | Default | Meaning |
|---|---|---|
| `PGF_CONNECTIONS` | `~/.config/pgf/connections` | folder of `*.conf` service files |
| `PGF_QUERIES` | `~/.config/pgf/queries` | folder of your own queries |
| `PGF_BUILTIN_QUERIES` | set by the package | folder of the built-in queries |
| `PGSERVICEFILE` | `~/.pg_service.conf` | the standard libpq service file |
| `PGSYSCONFDIR` | unset | folder of a system-wide `pg_service.conf` |
| `PSQL_PAGER` | `pspg` with Nix | pager for query results |
| `VISUAL`, `EDITOR` | `vi` | editor for `pgf edit` |

## Development

```bash
nix build          # the package
nix flake check    # shellcheck on bin/pgf
./bin/pgf --help   # runs straight from the checkout
```

## License

[MIT](LICENSE)
