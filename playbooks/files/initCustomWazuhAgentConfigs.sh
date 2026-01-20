#!/bin/bash

insert_block_before_line() {
  local block="$1"
  local search="$2"
  local file="$3"

  if awk -v search_block="$block" '
    BEGIN { RS=""; FS="\n" }
    $0 == search_block { found=1 }
    END { exit !found }
  ' "$file"; then
    echo "Duplicate Found"
    return
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

CONF='/var/ossec/etc/ossec.conf'

CONF_BLOCK=$(
  cat <<'EOF'
  <command>
    <name>block-ssh</name>
    <executable>block-ssh.sh</executable>
    <timeout_allowed>yes</timeout_allowed>
  </command>
  <active-response>
    <command>block-ssh</command>
    <location>local</location>
    <rules_id>100002</rules_id>
  </active-response>
EOF
)
CONF_SEARCH='</ossec_config>'

insert_block_before_line "$CONF_BLOCK" "$CONF_SEARCH" "$CONF"
