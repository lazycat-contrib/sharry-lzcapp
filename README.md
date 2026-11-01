# Sharry LazyCat community package

Upstream https://github.com/eikek/sharry (GPL-3.0), v1.17.0. Package `community.lazycat.app.sharry`, min OS 1.6.0 (needed for `run_as`), amd64, mirror delivery, community (喵喵) store only.

Single JVM container. Upstream's default config points at PostgreSQL and enables a fixed `admin:admin` login; this package changes both:

- **Database**: H2 file database at `/data/sharry.db` in PostgreSQL compatibility mode (the shipped migrations target that), so no external database is required and accounts plus uploaded files persist in one bind `/lzcapp/var/data:/data`.
- **No default credentials**: the fixed auth module is enabled only with the deployment-generated username and secret, so `admin:admin` does not exist. Self-service signup is `closed`; accounts beyond the admin are created inside the app.
- **Ownership**: the upstream image runs as uid/gid 10001 and there is no separate setup step, so `run_as: "10001:10001"` maps the persistent directory owner instead of a `setup_script` (the two are mutually exclusive).

`content/start.sh` validates the credentials (username `[A-Za-z0-9_.@-]`, secret at least 12 characters from a fixed safe set, base URL must be http/https without quotes), renders `sharry.conf` into tmpfs at `/run/sharry` with `chmod 600`, and then execs the unmodified upstream entrypoint. Nothing secret ships in the package or lands in the data volume.

Image `eikek0/sharry:v1.17.0` is delivered through the mirror with digest verification.

Not device-tested: login, upload, share link creation/expiry/zip download, alias inbox uploads, and persistence across restarts.
