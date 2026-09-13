#!/usr/bin/env bash
set -Eeuo pipefail

# Set NetworkManager autoconnect priorities without disconnecting connections.
# Ethernet is 600, ordinary Wi-Fi is 400, and hotspot-like Wi-Fi is 200.
# Profile names are inspected locally but never documented. Safe to rerun.
# Rollback: restore captured priorities with nmcli manually.

readonly ETHERNET_PRIORITY=600
readonly HOUSEHOLD_WIFI_PRIORITY=400
readonly HOTSPOT_PRIORITY=200
readonly HOTSPOT_REGEX='hotspot|phone|mobile|android|iphone|pixel|galaxy|samsung|tether|a56'
step() { printf '\n===== %s =====\n' "$1"; }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }

step 'Validate prerequisites'
[[ "$(id -u)" -eq 0 ]] || fail 'run through sudo from a trusted host terminal'
for command_name in nmcli awk grep sort paste; do
    command -v "$command_name" >/dev/null || fail "missing command: $command_name"
done
nmcli general status >/dev/null || fail 'NetworkManager is unavailable'
active_before="$(nmcli -t -g GENERAL.CONNECTION device show | sort | paste -sd '|' -)"
ethernet_count=0
wifi_count=0
hotspot_count=0

step 'Apply profile priorities'
while IFS= read -r uuid; do
    [[ -n "$uuid" ]] || continue
    profile_type="$(nmcli -g connection.type connection show uuid "$uuid")"
    profile_name="$(nmcli -g connection.id connection show uuid "$uuid")"
    case "$profile_type" in
        802-3-ethernet)
            priority="$ETHERNET_PRIORITY"; ethernet_count=$((ethernet_count + 1)) ;;
        802-11-wireless)
            priority="$HOUSEHOLD_WIFI_PRIORITY"; wifi_count=$((wifi_count + 1))
            if printf '%s\n' "$profile_name" | grep -Eiq "$HOTSPOT_REGEX"; then
                priority="$HOTSPOT_PRIORITY"; hotspot_count=$((hotspot_count + 1))
            fi ;;
        *) continue ;;
    esac
    old_priority="$(nmcli -g connection.autoconnect-priority connection show uuid "$uuid")"
    printf 'Profile type=%s priority=%s previous=%s\n' "$profile_type" "$priority" "${old_priority:-default}"
    nmcli connection modify uuid "$uuid" connection.autoconnect-priority "$priority"
done < <(nmcli -t -g UUID connection show)

(( ethernet_count > 0 )) || fail 'no Ethernet profile found'
(( wifi_count > 0 )) || fail 'no Wi-Fi profile found'
if (( hotspot_count == 0 )); then
    printf '%s\n' 'WARNING: no hotspot-like Wi-Fi profile was identified; review before relying on hotspot priority.'
fi

step 'Validate without disconnecting'
active_after="$(nmcli -t -g GENERAL.CONNECTION device show | sort | paste -sd '|' -)"
[[ "$active_before" == "$active_after" ]] || fail 'active connection state changed unexpectedly'
while IFS= read -r uuid; do
    [[ -n "$uuid" ]] || continue
    profile_type="$(nmcli -g connection.type connection show uuid "$uuid")"
    case "$profile_type" in
        802-3-ethernet|802-11-wireless)
            current="$(nmcli -g connection.autoconnect-priority connection show uuid "$uuid")"
            [[ "$current" =~ ^[0-9]+$ ]] || fail "invalid priority for profile type $profile_type" ;;
    esac
done < <(nmcli -t -g UUID connection show)
nmcli -f NAME,TYPE,AUTOCONNECT,AUTOCONNECT-PRIORITY connection show
printf '%s\n' 'Priorities applied; no connection was disconnected or reactivated.'
