#!/bin/sh
set -e

VAULT_ADDR="${VAULT_ADDR:-http://vault:8200}"
ROLE_ID=$(cat /vault-secrets/role_id)
SECRET_ID=$(cat /vault-secrets/secret_id)

echo "[entrypoint] Authenticating to Vault via AppRole..."
VAULT_TOKEN=$(python3 -c "
import json, urllib.request
req = urllib.request.Request(
    '${VAULT_ADDR}/v1/auth/approle/login',
    data=json.dumps({'role_id': '${ROLE_ID}', 'secret_id': '${SECRET_ID}'}).encode(),
    headers={'Content-Type': 'application/json'}
)
resp = json.load(urllib.request.urlopen(req))
print(resp['auth']['client_token'])
")

if [ -z "$VAULT_TOKEN" ]; then
  echo "[entrypoint] ERROR: failed to authenticate to Vault" >&2
  exit 1
fi

echo "[entrypoint] Fetching DB credentials from Vault..."
python3 -c "
import json, urllib.request
req = urllib.request.Request(
    '${VAULT_ADDR}/v1/secret/data/todo-app/db',
    headers={'X-Vault-Token': '${VAULT_TOKEN}'}
)
resp = json.load(urllib.request.urlopen(req))
data = resp['data']['data']
with open('/tmp/vault.env', 'w') as f:
    for k, v in data.items():
        f.write(f'{k}={v}\n')
"

set -a
. /tmp/vault.env
set +a
rm -f /tmp/vault.env

echo "[entrypoint] Secrets loaded. Starting application..."
exec python app.py
