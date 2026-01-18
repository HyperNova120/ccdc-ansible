#!/bin/bash

insert_block_before_line() {
  local block="$1"
  local search="$2"
  local file="$3"

  if awk -v RS="" search="$block" '$0 ~ search {exit 1}' <<<"$file"; then
    echo "Duplicate config entry found"
    return 1
  fi

  awk -v block="$block" -v search="$search" '
        BEGIN { inserted = 0 }
        {
            if (!inserted && $0 ~ search) {
                print block
                inserted = 1
            }
            print
        }
    ' "$file" >"${file}.tmp" && mv "${file}.tmp" "$file"
}

CONF="/var/ossec/etc/ossec.conf"

CONF_BLOCK="  <command>
    <name>block-ssh</name>
    <executable>block-ssh.sh</executable>
    <timeout_allowed>yes</timeout_allowed>
  </command>
  <active-response>
    <command>block-ssh</command>
    <location>local</location>
    <rules_id>100002</rules_id>
  </active-response>
"
CONF_SEARCH="</ossec_config>"

insert_block_before_line "$CONF_BLOCK" "$CONF_SEARCH" "$CONF"
