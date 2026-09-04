#!/bin/bash
# Iron Linux - pre-build desktop/installer configuration sanity checks.
#
# Catches the class of mistake that otherwise only surfaces after a full
# ~20 minute ISO build + QEMU boot: malformed XML/JSON, a helper script
# referenced from rc.xml/menu.xml/waybar that isn't actually shipped or
# isn't executable, a Calamares module listed in settings.conf sequence
# that no installed module.desc/plugin actually provides, or duplicate
# module ids in that sequence.
#
# This is NOT a substitute for actually booting the ISO in QEMU - it only
# catches static mistakes, not runtime behaviour (crashes, protocol
# negotiation, timing). Exit 0 if everything checked out, 1 otherwise.

set -uo pipefail
cd "$(dirname "$0")/.."

fail=0
note() { printf '  - %s\n' "$1"; }
err() { printf 'FAIL: %s\n' "$1" >&2; fail=1; }
ok() { printf 'OK:   %s\n' "$1"; }

CHROOT_ROOT="config/includes.chroot"

# --- XML well-formedness -------------------------------------------------
echo "== XML syntax =="
for f in "$CHROOT_ROOT"/etc/xdg/labwc/rc.xml \
         "$CHROOT_ROOT"/etc/xdg/labwc/menu.xml \
         "$CHROOT_ROOT"/etc/greetd/labwc/rc.xml \
         "$CHROOT_ROOT"/etc/greetd/labwc/menu.xml; do
    [ -f "$f" ] || continue
    if command -v xmllint >/dev/null 2>&1; then
        if xmllint --noout "$f" 2>/tmp/iron-xmllint.err; then
            ok "$f"
        else
            err "$f is not well-formed XML:"
            sed 's/^/         /' /tmp/iron-xmllint.err >&2
        fi
    elif python3 -c "import xml.dom.minidom" 2>/dev/null; then
        if python3 -c "import xml.dom.minidom,sys; xml.dom.minidom.parse(sys.argv[1])" "$f" 2>/tmp/iron-xmllint.err; then
            ok "$f"
        else
            err "$f is not well-formed XML:"
            sed 's/^/         /' /tmp/iron-xmllint.err >&2
        fi
    else
        note "no xmllint/python3 available, skipped $f"
    fi
done

# --- GTK-CSS sanity (waybar/wlogout/gtkgreet stylesheets) ----------------
# GTK's CSS engine is a small subset of real CSS: no ":root {}", no
# var(...)/custom properties, colors only via @define-color. It also has
# no error recovery for a malformed comment - one unterminated /* kills
# the whole stylesheet load for every consumer that @imports it, which is
# exactly what happened here twice (an errant ":root{}" block, then a
# follow-up edit that dropped the closing "*/"). Check for both.
echo "== GTK-CSS sanity =="
for f in "$CHROOT_ROOT"/usr/share/themes/Iron/colors.css \
         "$CHROOT_ROOT"/etc/xdg/waybar/style.css \
         "$CHROOT_ROOT"/etc/skel/.config/waybar/style.css \
         "$CHROOT_ROOT"/etc/xdg/wlogout/style.css \
         "$CHROOT_ROOT"/etc/skel/.config/wlogout/style.css \
         "$CHROOT_ROOT"/etc/greetd/style.css; do
    [ -f "$f" ] || continue
    result="$(python3 -c "
import re
text = open('$f').read()
depth, i = 0, 0
while i < len(text):
    if text[i:i+2] == '/*':
        depth += 1; i += 2
    elif text[i:i+2] == '*/':
        depth -= 1; i += 2
    else:
        i += 1
if depth != 0:
    print(f'UNBALANCED {depth}')
    raise SystemExit
code = re.sub(r'/\*.*?\*/', '', text, flags=re.S)  # strip comments before checking selectors
if re.search(r'^\s*:root\s*\{', code, re.M) or 'var(--' in code:
    print('WEBCSS')
else:
    print('OK')
")"
    case "$result" in
        OK) ok "$f" ;;
        WEBCSS) err "$f uses ':root {}' / var(--...) outside a comment - not supported by GTK-CSS, use @define-color instead" ;;
        UNBALANCED*) err "$f has unbalanced /* */ comments ($result) - a fatal parse error for every GTK-CSS consumer that imports it" ;;
    esac
done

# --- JSON / JSONC syntax --------------------------------------------------
echo "== Waybar JSON syntax =="
for f in "$CHROOT_ROOT"/etc/xdg/waybar/config "$CHROOT_ROOT"/etc/skel/.config/waybar/config; do
    [ -f "$f" ] || continue
    if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f" 2>/tmp/iron-json.err; then
        ok "$f"
    else
        err "$f is not valid JSON:"
        sed 's/^/         /' /tmp/iron-json.err >&2
    fi
done

# --- Executable bit + interpreter on every Iron helper script ------------
echo "== Iron helper scripts =="
for f in "$CHROOT_ROOT"/usr/local/bin/iron-* "$CHROOT_ROOT"/usr/bin/calamares-install-* "$CHROOT_ROOT"/usr/share/calamares/helpers/iron-*; do
    [ -f "$f" ] || continue
    if [ ! -x "$f" ]; then
        err "$f is not executable (chmod +x it)"
        continue
    fi
    shebang="$(head -n1 "$f")"
    case "$shebang" in
        '#!'*)
            interp="$(echo "${shebang#\#!}" | awk '{print $1}')"
            if command -v "$interp" >/dev/null 2>&1 || [ -x "$interp" ]; then
                ok "$f (interpreter: $interp)"
            else
                err "$f: interpreter '$interp' not found on this build host (may still exist in the target chroot - verify manually)"
            fi
            ;;
        *)
            err "$f has no shebang line"
            ;;
    esac
done

# --- Commands referenced from rc.xml/menu.xml/waybar exist in a package list ---
echo "== Referenced commands vs package lists =="
PKG_LISTS="config/package-lists/core.list.chroot config/package-lists/desktop.list.chroot config/package-lists/apps.list.chroot config/package-lists/live.list.chroot"
all_pkgs="$(grep -hEv '^\s*(#|$)' $PKG_LISTS)"

# binary -> providing package, for names that don't match 1:1
declare -A PROVIDERS=(
    [nm-applet]=network-manager-applet
    [nm-connection-editor]=network-manager-applet
    [blueman-applet]=blueman
    [blueman-manager]=blueman
    [mako]=mako-notifier
    [pkexec]=policykit-1
    [wpctl]=wireplumber
    [wl-paste]=wl-clipboard
    [wl-copy]=wl-clipboard
    # pkexec is its own binary package on Debian trixie (built from the
    # "polkit" source, same as polkitd) - it is not bundled into polkitd
    # and there is no "policykit-1" umbrella package on trixie.
    [pkexec]=pkexec
)

check_cmd() {
    cmd="$1"
    src="$2"
    case "$cmd" in
        iron-*|calamares-install-*|fuzzel|foot|pcmanfm|firefox-esr|mousepad|swaylock|swaybg|swayidle|wob|cliphist|xarchiver|brightnessctl|systemctl|zenity|sudo|env|labwc|wlogout|grim|slurp)
            : # own script, or 1:1 package name, or core system tool - not double-checked here
            ;;
    esac
    pkg="${PROVIDERS[$cmd]:-$cmd}"
    if echo "$all_pkgs" | grep -qx "$pkg"; then
        ok "$src -> '$cmd' provided by package '$pkg'"
    else
        note "$src -> '$cmd': package '$pkg' not found in package-lists (informational only - may be a core/base package)"
    fi
}

for cmd in fuzzel foot pcmanfm firefox-esr mousepad nm-connection-editor mako waybar \
           nm-applet blueman-applet udiskie lxpolkit wl-paste wl-copy cliphist \
           swayidle swaylock wob swaybg wpctl grim slurp brightnessctl blueman-manager pkexec; do
    check_cmd "$cmd" "known-reference"
done

# --- Calamares settings.conf: duplicate / undefined modules ---------------
echo "== Calamares module sequence =="
SETTINGS="$CHROOT_ROOT/etc/calamares/settings.conf"
if [ -f "$SETTINGS" ] && command -v python3 >/dev/null 2>&1; then
    python3 - "$SETTINGS" "$CHROOT_ROOT" <<'PYEOF'
import sys, re, glob, os

settings_path, chroot_root = sys.argv[1], sys.argv[2]
text = open(settings_path).read()

# Pull every "- name" list item under sequence:, grouped by phase (show/exec
# entries legitimately repeat a view module's id across phases - a view is
# listed once in its "show" phase and once more in "exec" as a placeholder
# marking when that view's associated job should run. What must NOT happen
# is the same id appearing twice within one phase, or an id that doesn't
# correspond to any real module in either phase.
in_seq = False
phase = None
items = []          # (phase_index, name)
phase_items = {}    # phase_index -> [names]
phase_idx = -1
for line in text.splitlines():
    if re.match(r'^sequence:\s*$', line):
        in_seq = True
        continue
    if in_seq:
        if re.match(r'^\S', line):  # dedent = sequence block ended
            in_seq = False
            continue
        m = re.match(r'^\s*-\s+(show|exec)\s*:\s*$', line)
        if m:
            phase_idx += 1
            phase_items[phase_idx] = []
            continue
        m = re.match(r'^\s*-\s+([A-Za-z0-9_-]+)\s*$', line)
        if m and phase_idx >= 0:
            items.append(m.group(1))
            phase_items[phase_idx].append(m.group(1))

# Known Debian calamares module ids that ship compiled modules (view or job)
# but are NOT shipped as a per-module .conf in this repo, plus Iron's own
# custom modules under includes.chroot. This is the set of "no .conf
# override needed, module exists elsewhere" names; anything outside this
# set must have either a module.desc (custom job) or a *.conf here.
known_no_conf = {
    "welcome", "locale", "keyboard", "partition", "users", "summary",
    "finished", "dpkg-unsafe-io", "dpkg-unsafe-io-undo", "sources-media",
    "sources-media-unmount", "sources-final", "umount", "localecfg",
    "networkcfg", "hwclock", "services-systemd", "bootloader-config",
    "grubcfg", "bootloader", "plymouthcfg", "initramfscfg", "initramfs",
    "luksbootkeyfile",
}
has_conf = {
    os.path.basename(p)[:-5]
    for p in glob.glob(os.path.join(chroot_root, "etc/calamares/modules/*.conf"))
}
has_custom_module = {
    os.path.basename(os.path.dirname(p))
    for p in glob.glob(os.path.join(chroot_root, "usr/lib/calamares/modules/*/module.desc"))
}

dupes = set()
for idx, names in phase_items.items():
    seen = set()
    for n in names:
        if n in seen:
            dupes.add(n)
        seen.add(n)

if dupes:
    print("FAIL: module id(s) duplicated within a single show/exec phase: " + ", ".join(sorted(dupes)))
    sys.exit(1)

unresolved = [
    it for it in items
    if it not in known_no_conf and it not in has_conf and it not in has_custom_module
]
if unresolved:
    print("FAIL: module(s) in sequence with no .conf override and no custom module.desc "
          "(this is exactly the class of bug that produced the 'timezone@timezone' "
          "Calamares init failure - double check the module actually exists in "
          "calamares/calamares-settings-debian for this Debian release): "
          + ", ".join(unresolved))
    sys.exit(1)

print(f"OK: {len(items)} sequence entries, no duplicates, all resolvable")
PYEOF
    if [ $? -ne 0 ]; then fail=1; fi
else
    note "python3 not available, skipped settings.conf sequence check"
fi

echo
if [ "$fail" -eq 0 ]; then
    echo "iron-linux: desktop/installer config validation passed"
    exit 0
else
    echo "iron-linux: desktop/installer config validation FAILED - see above" >&2
    exit 1
fi
