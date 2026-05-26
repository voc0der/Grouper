#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
addon_name="Grouper"
toc_file="${repo_root}/${addon_name}.toc"
package_dir="${1:?usage: stage-addon.sh <package-dir>}"

rm -rf "${package_dir}"
mkdir -p "${package_dir}"

cp "${toc_file}" "${package_dir}/${addon_name}.toc"

while IFS= read -r raw_line || [[ -n "${raw_line}" ]]; do
  line="${raw_line%$'\r'}"

  case "${line}" in
    ""|\#*)
      continue
      ;;
  esac

  source_path="${repo_root}/${line}"
  target_path="${package_dir}/${line}"

  if [[ ! -e "${source_path}" ]]; then
    echo "Missing TOC entry: ${line}" >&2
    exit 1
  fi

  mkdir -p "$(dirname "${target_path}")"
  cp -R "${source_path}" "${target_path}"
done < "${toc_file}"
