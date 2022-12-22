#!/usr/bin/env bash

dfx-network-stop
sleep 2
ss -ltpn
dfx-network-deploy --prodlike --verbose
sleep 4
ss -ltpn
dfx-status
prod_version="$(dfx-software-internet-identity-version --mainnet)"
local_version="$(dfx-software-internet-identity-version --network local)"
[[ "$prod_version" == "$local_version" ]] || {
  echo "ERROR: Version mismatch:"
  echo "prod:  $prod_version"
  echo "local: $local_version"
  exit 1
} >&2
dfx-network-stop
