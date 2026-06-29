#!/bin/sh
set -eu

: "${MINIO_ROOT_USER:?MINIO_ROOT_USER is required}"
: "${MINIO_ROOT_PASSWORD:?MINIO_ROOT_PASSWORD is required}"

data_dir="${SEAWEEDFS_DATA_DIR:-/data}"
runtime_dir="${SEAWEEDFS_RUNTIME_DIR:-$data_dir/.agenthub-seaweedfs}"
config_file="$runtime_dir/s3.json"

json_escape() {
  JSON_VALUE="$1" awk 'BEGIN {
    s = ENVIRON["JSON_VALUE"]
    gsub(/\\/, "\\\\", s)
    gsub(/"/, "\\\"", s)
    gsub(/\r/, "\\r", s)
    gsub(/\n/, "\\n", s)
    gsub(/\t/, "\\t", s)
    printf "%s", s
  }'
}

mkdir -p "$runtime_dir"

access_key="$(json_escape "$MINIO_ROOT_USER")"
secret_key="$(json_escape "$MINIO_ROOT_PASSWORD")"

cat > "$config_file" <<EOF
{
  "identities": [
    {
      "name": "agenthub",
      "credentials": [
        {
          "accessKey": "$access_key",
          "secretKey": "$secret_key"
        }
      ],
      "actions": ["Read", "Write", "List", "Tagging", "Admin"]
    }
  ]
}
EOF

exec /usr/bin/weed "$@"
