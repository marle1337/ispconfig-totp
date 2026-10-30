#!/bin/sh
#
# Check that the authenticator app login is still in place on an ISPConfig
# panel. Meant for cron and for right after an ISPConfig update:
#
#   sudo ./check.sh [-v] [path-to-ispconfig-interface]
#
# Silent and exit 0 when all is well (-v prints each check), otherwise one
# line per problem and exit 1, so cron mails the output. Problems found:
#
#   - module or scripts missing (an update removed them: logins skip the app)
#   - installed version differs from this checkout
#   - ISPConfig updated since the install (run install.sh and tests/e2e.sh)
#   - a hook in ISPConfig the plugin relies on is gone
#   - key file missing, wrong size or readable by others
#   - "Force password change after X days" above 0
#
# Run it from a root-owned checkout: cron runs it as root.
#
set -u

VERBOSE=0
INTERFACE=""
for arg in "$@"; do
	case "$arg" in
		-v) VERBOSE=1 ;;
		-*) printf 'error: unknown option %s (known: -v)\n' "$arg" >&2; exit 2 ;;
		*) INTERFACE="$arg" ;;
	esac
done
INTERFACE="${INTERFACE:-/usr/local/ispconfig/interface}"
HERE="$(cd "$(dirname "$0")" && pwd)"
WEB="$INTERFACE/web"
TARGET="$WEB/totpauth"
KEY="$(dirname "$INTERFACE")/totpauth/secret.key"

. "$HERE/install/hooks.sh"

problems=0
ok()      { [ "$VERBOSE" = 1 ] && printf 'ok       %s\n' "$1"; return 0; }
problem() { printf 'PROBLEM  %s\n' "$1"; problems=$((problems + 1)); }

if [ ! -f "$INTERFACE/lib/config.inc.php" ]; then
	problem "$INTERFACE/lib/config.inc.php not found - pass the interface path"
	exit 1
fi

# ---- files -----------------------------------------------------------------
missing_files=""
for f in "$TARGET/lib/plugin.d/totpauth_plugin.inc.php" "$TARGET/lib/common.inc.php" "$TARGET/verify.php" "$TARGET/api.php" "$WEB/js/js.d/totpauth.js" "$WEB/js/js.d/totpauth-qr.js"; do
	[ -f "$f" ] || missing_files="$missing_files ${f#"$INTERFACE"/}"
done
if [ -n "$missing_files" ]; then
	problem "files missing:$missing_files - logins may skip the app, run install.sh"
else
	ok "module and scripts installed"
fi

# ---- versions --------------------------------------------------------------
readv() { [ -f "$1" ] && tr -d ' \r\n' < "$1"; }
want="$(readv "$HERE/VERSION")"
have="$(readv "$TARGET/VERSION")"
if [ -n "$have" ] && [ "$have" != "$want" ]; then
	problem "installed totpauth $have, this checkout is $want - run install.sh"
elif [ -n "$have" ]; then
	ok "totpauth $have"
fi

panel="$(totpauth_ispc_version "$INTERFACE")"
installed_for="$(readv "$TARGET/ISPC_VERSION")"
if [ -z "$installed_for" ]; then
	[ -d "$TARGET" ] && problem "no ISPC_VERSION in the module (installed before 0.2.0?) - run install.sh"
elif [ "$installed_for" != "$panel" ]; then
	problem "ISPConfig is $panel, the module was installed for $installed_for - run install.sh, then tests/e2e.sh"
else
	ok "installed for ISPConfig $panel"
fi

# ---- hooks -----------------------------------------------------------------
if hooks="$(totpauth_hooks "$INTERFACE")"; then
	ok "hooks in ISPConfig found"
else
	printf '%s\n' "$hooks" | while IFS= read -r line; do printf 'PROBLEM  %s\n' "$line"; done
	problems=$((problems + 1))
fi

# ---- key -------------------------------------------------------------------
if [ ! -f "$KEY" ]; then
	problem "key file $KEY missing - restore it from the backup"
else
	size="$(wc -c < "$KEY" | tr -d ' ')"
	mode="$(ls -l "$KEY" | cut -c5-10)"
	if [ "$size" != "32" ]; then
		problem "key file $KEY holds $size bytes instead of 32 - restore it from the backup"
	elif [ "$mode" != "------" ]; then
		problem "key file $KEY is readable by group or others ($(ls -l "$KEY" | cut -c1-10)) - chmod 400"
	else
		ok "key file"
	fi
fi

# ---- forced password change --------------------------------------------------
# Tests replace the database step with TOTPAUTH_SETUP_CMD, never as root.
if [ -n "${TOTPAUTH_SETUP_CMD:-}" ] && [ "$(id -u)" != "0" ]; then
	setup() { "$TOTPAUTH_SETUP_CMD" "$@"; }
else
	setup() { php "$HERE/install/setup.php" "$@"; }
fi
if [ -n "${TOTPAUTH_SETUP_CMD:-}" ] || command -v php >/dev/null 2>&1; then
	if check="$(setup "$INTERFACE" check 2>&1)"; then
		days="$(printf '%s\n' "$check" | sed -n 's/^force_days=\([0-9]*\)$/\1/p')"
		if [ -z "$days" ]; then
			problem "database check gave no answer ($check)"
		elif [ "$days" -gt 0 ]; then
			problem "\"Force password change after X days\" is $days - users with an old password sign in without the app, set it to 0"
		else
			ok "forced password change off"
		fi
	else
		problem "database check failed: $check"
	fi
else
	problem "php not found, cannot check the forced password change"
fi

[ "$problems" -eq 0 ] || exit 1
ok "all checks passed"
