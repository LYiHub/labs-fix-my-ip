#!/usr/bin/env bash

set -uo pipefail

GATEWAY="${GATEWAY:-192.168.14.9}"
DNS="${DNS:-198.18.0.2}"
STATE_FILE="${STATE_FILE:-/var/tmp/fix-my-ip-macos-services.txt}"

usage() {
  cat <<'EOF'
Usage:
  sudo ./fix-ip-macos.sh apply
  sudo ./fix-ip-macos.sh restore

Modes:
  apply    Keep each current IPv4 address/subnet mask, set gateway and DNS.
  restore  Restore touched services to DHCP address and automatic DNS.

Optional environment variables:
  GATEWAY     Default: 192.168.14.9
  DNS         Default: 198.18.0.2
  STATE_FILE  Default: /var/tmp/fix-my-ip-macos-services.txt
EOF
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Error: this script must be run with sudo." >&2
    exit 1
  fi
}

is_ipv4() {
  local value="$1"

  [[ -n "${value}" ]] || return 1
  [[ "${value}" != "none" ]] || return 1
  [[ "${value}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
}

list_enabled_services() {
  networksetup -listallnetworkservices | tail -n +2 | while IFS= read -r service; do
    [[ -n "${service}" ]] || continue

    case "${service}" in
      \**) continue ;;
    esac

    printf '%s\n' "${service}"
  done
}

get_info_value() {
  local info="$1"
  local key="$2"

  printf '%s\n' "${info}" | awk -F': ' -v key="${key}" '$1 == key { print $2; exit }'
}

apply_settings() {
  local touched=0
  local failed=0

  : > "${STATE_FILE}"

  while IFS= read -r service; do
    local info ip subnet

    info="$(networksetup -getinfo "${service}" 2>/dev/null || true)"
    ip="$(get_info_value "${info}" "IP address")"
    subnet="$(get_info_value "${info}" "Subnet mask")"

    if ! is_ipv4 "${ip}" || ! is_ipv4 "${subnet}"; then
      echo "Skip ${service}: no current IPv4 address/subnet mask."
      continue
    fi

    echo "Apply ${service}: IP=${ip}, subnet=${subnet}, gateway=${GATEWAY}, DNS=${DNS}"

    if networksetup -setmanual "${service}" "${ip}" "${subnet}" "${GATEWAY}" \
      && networksetup -setdnsservers "${service}" "${DNS}"; then
      printf '%s\n' "${service}" >> "${STATE_FILE}"
      touched=$((touched + 1))
    else
      echo "Error: failed to update ${service}." >&2
      failed=1
    fi
  done < <(list_enabled_services)

  if [[ "${touched}" -eq 0 ]]; then
    rm -f "${STATE_FILE}"
    echo "No active IPv4 network services were updated." >&2
    return 1
  fi

  echo "Updated ${touched} network service(s)."
  return "${failed}"
}

restore_service() {
  local service="$1"

  [[ -n "${service}" ]] || return 0

  echo "Restore ${service}: DHCP address, automatic DNS."

  if networksetup -setdhcp "${service}" \
    && networksetup -setdnsservers "${service}" Empty; then
    return 0
  fi

  echo "Error: failed to restore ${service}." >&2
  return 1
}

restore_settings() {
  local failed=0
  local restored=0

  if [[ -s "${STATE_FILE}" ]]; then
    while IFS= read -r service; do
      if restore_service "${service}"; then
        restored=$((restored + 1))
      else
        failed=1
      fi
    done < "${STATE_FILE}"

    [[ "${failed}" -eq 0 ]] && rm -f "${STATE_FILE}"
  else
    echo "State file not found. Restoring all enabled network services."

    while IFS= read -r service; do
      if restore_service "${service}"; then
        restored=$((restored + 1))
      else
        failed=1
      fi
    done < <(list_enabled_services)
  fi

  echo "Restored ${restored} network service(s)."
  return "${failed}"
}

main() {
  local mode="${1:-}"

  case "${mode}" in
    apply)
      require_root
      apply_settings
      ;;
    restore)
      require_root
      restore_settings
      ;;
    -h|--help|help|"")
      usage
      ;;
    *)
      echo "Error: unknown mode '${mode}'." >&2
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
