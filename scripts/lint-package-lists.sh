#!/bin/bash
# Iron Linux - sanity-check the package lists.
#
# Cheap static validation that doesn't require live-build or network
# access: catches duplicate package names (within and across lists,
# since live-build concatenates all config/package-lists/*.list.chroot
# files) and obviously malformed lines. Does NOT check that packages
# actually exist in Debian's archive - that requires a real apt/dpkg
# environment, which is out of scope for this bootstrap task.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

LIST_DIR="config/package-lists"
STATUS=0

if ! compgen -G "${LIST_DIR}"/*.list.chroot > /dev/null; then
    echo "No package lists found in ${LIST_DIR}" >&2
    exit 1
fi

echo "Checking package lists in ${LIST_DIR}..."

# Malformed lines: anything that isn't a comment, blank, or a bare
# package name (lowercase letters, digits, +, -, .).
for f in "${LIST_DIR}"/*.list.chroot; do
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        [[ "$line" == \#* ]] && continue
        if ! [[ "$line" =~ ^[a-z0-9][a-z0-9+.-]*$ ]]; then
            echo "MALFORMED  $f: '$line'"
            STATUS=1
        fi
    done < "$f"
done

# Duplicates across the whole package set (harmless to apt, but usually
# a sign a package was listed in the wrong file or copy-pasted twice).
DUPES=$(grep -h -v '^\s*#' "${LIST_DIR}"/*.list.chroot | grep -v '^\s*$' | sort | uniq -d || true)
if [[ -n "$DUPES" ]]; then
    echo "DUPLICATE package(s) across lists:"
    echo "$DUPES" | sed 's/^/  /'
    STATUS=1
fi

if [[ "$STATUS" -eq 0 ]]; then
    TOTAL=$(grep -h -v '^\s*#' "${LIST_DIR}"/*.list.chroot | grep -c -v '^\s*$' || true)
    echo "OK - ${TOTAL} package entries across $(ls "${LIST_DIR}"/*.list.chroot | wc -l) list(s)."
fi

exit "$STATUS"
