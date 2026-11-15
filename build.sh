#!/bin/sh
set -eu

if [ "$#" -ne 0 ]; then
    echo "Usage: $0" >&2
    exit 2
fi

root=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
[ "$(uname -s)" = Linux ] || {
    echo "This script must run natively on Linux; cross-compilation is not supported." >&2
    exit 1
}
case "$(uname -m)" in
    aarch64|arm64) arch=arm64 ;;
    x86_64|amd64) arch=amd64 ;;
    *) echo "Unsupported Linux architecture." >&2; exit 1 ;;
esac
for command in curl sha256sum tar make cc c++; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Required build tool not found: $command" >&2
        exit 1
    fi
done
output=${OPENMPI_OUTPUT_DIR:-"$root/../binaries/openmpi/$arch"}
mkdir -p "$output"
output=$(CDPATH= cd -- "$output" && pwd)
archive="$output/openmpi-4.1.8-linux-$arch.tar.gz"
if [ -e "$archive" ]; then
    echo "Archive already exists: $archive (remove it before rebuilding)" >&2
    exit 1
fi

work=$(mktemp -d "${TMPDIR:-/tmp}/openmpi-build.XXXXXXXX")
output_tmp=
trap 'rm -rf "$work"; if [ -n "$output_tmp" ]; then rm -f "$output_tmp"; fi' EXIT
trap 'exit 1' HUP INT TERM
curl -fsSL https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-4.1.8.tar.gz -o "$work/source.tar.gz"
printf '%s  %s\n' fb41086bbed9300baa2f3d7572491facfe5257412fa524ec5a396aa9101d5c62 "$work/source.tar.gz" | sha256sum -c -
mkdir "$work/source"
tar -xzf "$work/source.tar.gz" -C "$work/source" --strip-components=1
cd "$work/source"
./configure --prefix=/opt/openmpi/4.1.8 --disable-mpi-fortran --disable-static \
    --without-verbs --with-hwloc=internal --with-libevent=internal
make -j2
make DESTDIR="$work/stage" install
install -Dm644 LICENSE "$work/stage/opt/openmpi/4.1.8/share/doc/openmpi/LICENSE"
tar -czf "$work/openmpi.tar.gz" -C "$work/stage/opt/openmpi/4.1.8" .
output_tmp=$(mktemp "$output/.openmpi.XXXXXXXX")
cp "$work/openmpi.tar.gz" "$output_tmp"
chmod 644 "$output_tmp"
ln "$output_tmp" "$archive" || { echo "Cannot create archive: $archive" >&2; exit 1; }
printf 'Created %s\n' "$archive"
