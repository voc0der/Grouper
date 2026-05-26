#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
addon_name="Grouper"
tmpdir="$(mktemp -d)"

cleanup() {
  rm -rf "${tmpdir}"
}

trap cleanup EXIT

expected_dir="${tmpdir}/expected/${addon_name}"
release_dir="${tmpdir}/release/${addon_name}"

bash "${repo_root}/.github/scripts/stage-addon.sh" "${expected_dir}"
mkdir -p "${release_dir}"

mapfile -t ignored_paths < <(
  awk '
    /^ignore:/ { in_ignore = 1; next }
    in_ignore && /^  - / { sub(/^  - /, ""); print; next }
    in_ignore { exit }
  ' "${repo_root}/.pkgmeta"
)

cd "${repo_root}"
shopt -s dotglob nullglob

for path in *; do
  case "${path}" in
    .git|.pkgmeta|dist)
      continue
      ;;
  esac

  skip=false
  for ignored_path in "${ignored_paths[@]}"; do
    if [[ "${path}" == "${ignored_path}" ]]; then
      skip=true
      break
    fi
  done

  if [[ "${skip}" == true ]]; then
    continue
  fi

  cp -R "${path}" "${release_dir}/${path}"
done

if ! diff -ruN "${expected_dir}" "${release_dir}"; then
  echo "Release package contents do not match the runtime addon files." >&2
  exit 1
fi

cd "${release_dir}"
find . -type f | sort
