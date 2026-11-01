#!/bin/sh
# Render the deployment credentials into a Sharry HOCON config at container
# start, then hand over to the unmodified upstream entrypoint.
#
# Why a wrapper: HOCON would happily accept a value containing a quote or a
# newline, which could break the document or inject extra settings. The
# credentials are validated here and written to tmpfs at /run, so no secret is
# shipped in the package or stored inside the data volume. Only the resulting
# H2 database keeps the accounts, which is what makes them persist.
set -eu

ADMIN_USER="${SHARRY_ADMIN_USER:-}"
ADMIN_PASS="${SHARRY_ADMIN_PASS:-}"
BASE_URL="${SHARRY_BASE_URL:-http://localhost:9090}"

fail() {
    echo "[sharry] refusing to start: $1" >&2
    # Never echo the offending value itself.
    exit 1
}

[ -n "$ADMIN_USER" ] || fail "SHARRY_ADMIN_USER must be set"
[ -n "$ADMIN_PASS" ] || fail "SHARRY_ADMIN_PASS must be set"

case "$ADMIN_USER" in
    *[!A-Za-z0-9_.@-]*) fail "SHARRY_ADMIN_USER may only contain letters, digits and _ . @ -" ;;
esac
case "$ADMIN_PASS" in
    *[!A-Za-z0-9_.~!@#%^+=-]*) fail "SHARRY_ADMIN_PASS contains unsupported characters" ;;
esac
[ "${#ADMIN_PASS}" -ge 12 ] || fail "SHARRY_ADMIN_PASS must be at least 12 characters"

case "$BASE_URL" in
    http://*|https://*) ;;
    *) fail "SHARRY_BASE_URL must start with http:// or https://" ;;
esac
case "$BASE_URL" in
    *[\"\']*) fail "SHARRY_BASE_URL must not contain quotes" ;;
esac

CONF_DIR=/run/sharry
CONF="$CONF_DIR/sharry.conf"
mkdir -p "$CONF_DIR"
chmod 700 "$CONF_DIR"

sed \
    -e "s|{{BASE_URL}}|$BASE_URL|g" \
    -e "s|{{ADMIN_USER}}|$ADMIN_USER|g" \
    -e "s|{{ADMIN_PASS}}|$ADMIN_PASS|g" \
    -e "s|{{FIXED_ENABLED}}|true|g" \
    /lzcapp/pkg/content/sharry.conf > "$CONF"
chmod 600 "$CONF"

# Hand over to the unmodified upstream entrypoint with the rendered config.
exec /opt/sharry/bin/sharry-restserver "$CONF"
