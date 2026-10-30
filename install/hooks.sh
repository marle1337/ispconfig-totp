# hooks.sh — the places in ISPConfig this module relies on. Sourced by
# install.sh and check.sh, so both look for exactly the same things.
#
#   totpauth_hooks <interface-path>
#
# Prints one line per missing hook and returns 1 if any is missing.

totpauth_hooks() {
	_iface="$1"
	_web="$_iface/web"
	_missing=0
	grep -q "plugin.d" "$_iface/lib/classes/plugin.inc.php" 2>/dev/null \
		|| { printf '%s\n' "lib/classes/plugin.inc.php no longer loads web/<module>/lib/plugin.d - the plugin would never run"; _missing=1; }
	grep -q "raiseEvent('login'" "$_web/login/index.php" 2>/dev/null \
		|| { printf '%s\n' "login/index.php no longer raises the login event - the app would be skipped at login"; _missing=1; }
	grep -q "js.d" "$_web/index.php" 2>/dev/null \
		|| { printf '%s\n' "index.php no longer loads js/js.d - the profile would show no setup"; _missing=1; }
	grep -q "s_pending" "$_web/login/index.php" 2>/dev/null \
		|| { printf '%s\n' "login/index.php no longer parks sessions in s_pending - this version of ISPConfig is not supported"; _missing=1; }
	return $_missing
}

# ISPC_APP_VERSION from lib/config.inc.php, empty if not found.
totpauth_ispc_version() {
	sed -n "s/.*define('ISPC_APP_VERSION',[ ]*'\([^']*\)').*/\1/p" "$1/lib/config.inc.php" | head -1
}
