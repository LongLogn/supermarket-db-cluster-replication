#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
MASTER_SERVICE=${MASTER_SERVICE:-mysql-master}
ROOT_PASS=${MYSQL_ROOT_PASSWORD:-rootpassword}
REPL_USER=${REPL_USER:-repl_user}
REPL_PASS=${REPL_PASS:-matkhau123}
SLAVE_SERVICE_LIST=(mysql-slave-1 mysql-slave-2)

for _ in {1..30}; do
  if docker exec "$MASTER_SERVICE" mysql -uroot -p"$ROOT_PASS" -e "SELECT 1" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

MASTER_STATUS=$(docker exec "$MASTER_SERVICE" mysql -uroot -p"$ROOT_PASS" -e "SHOW MASTER STATUS\G")
MASTER_LOG_FILE=$(printf "%s\n" "$MASTER_STATUS" | awk '/File: / {print $2}')
MASTER_LOG_POS=$(printf "%s\n" "$MASTER_STATUS" | awk '/Position: / {print $2}')

if [[ -z "$MASTER_LOG_FILE" || -z "$MASTER_LOG_POS" ]]; then
  echo "Unable to get MASTER status. Check mysql-master container." >&2
  exit 1
fi

echo "Master status: $MASTER_LOG_FILE at $MASTER_LOG_POS"

for slave in "${SLAVE_SERVICE_LIST[@]}"; do
  echo "Resetting state on $slave before replication..."
  docker exec "$slave" mysql -uroot -p"$ROOT_PASS" -e "
    STOP SLAVE;
    RESET SLAVE ALL;
    DROP DATABASE IF EXISTS supermarket;
  " || true

  docker exec "$slave" mysql -uroot -p"$ROOT_PASS" -e "CREATE DATABASE IF NOT EXISTS supermarket;"

  echo "Loading schema on $slave..."
  docker exec -i "$slave" mysql -uroot -p"$ROOT_PASS" < "$REPO_ROOT/database/01_schema.sql"

  echo "Configuring $slave ..."
  docker exec "$slave" mysql -uroot -p"$ROOT_PASS" -e "
    CHANGE MASTER TO
      MASTER_HOST='mysql-master',
      MASTER_USER='${REPL_USER}',
      MASTER_PASSWORD='${REPL_PASS}',
      MASTER_LOG_FILE='${MASTER_LOG_FILE}',
      MASTER_LOG_POS=${MASTER_LOG_POS};
    START SLAVE;
  "

  echo "--- $slave status ---"
  docker exec "$slave" mysql -uroot -p"$ROOT_PASS" -e "SHOW SLAVE STATUS\G" | sed -n '1,30p'
  echo
  echo "Replication setup complete for $slave"
done
