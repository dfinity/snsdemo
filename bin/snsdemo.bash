# shellcheck shell=bash
# Shared helpers for the snsdemo scripts.  Source this file; do not execute it.
#
# Conventions:
# - DFX_NETWORK selects the network.  The variable keeps its historical name so
#   that existing callers keep working.  "local" and "bare" are managed networks
#   that are defined in icp.yaml.  "ic" and "mainnet" select the IC mainnet.
#   Any other value must be the name of a network and environment in icp.yaml.
# - snsdemo keeps its own state (canister IDs, neuron IDs, exported pem files) in
#   $SNSDEMO_STATE_DIR, which is .snsdemo/ in the project root by default.
# - All icp-cli commands run against the project in $ICP_PROJECT_ROOT, which is
#   the root of this repository by default.

SNSDEMO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
export SNSDEMO_ROOT
export ICP_PROJECT_ROOT="${ICP_PROJECT_ROOT:-$SNSDEMO_ROOT}"
export SNSDEMO_STATE_DIR="${SNSDEMO_STATE_DIR:-$SNSDEMO_ROOT/.snsdemo}"
# Make sure that the first run of icp does not print anything unexpected.
export ICP_TELEMETRY_DISABLED="${ICP_TELEMETRY_DISABLED:-1}"

# Prints an error message and exits.
snsdemo_die() {
  echo "ERROR: $*" >&2
  exit 1
}

# Checks that the given commands are installed.
snsdemo_require() {
  local tool
  for tool in "$@"; do
    command -v "$tool" >/dev/null || snsdemo_die "'$tool' was not found.  Please install the tools in mise.toml with 'mise install'."
  done
}

# The name of the icp-cli environment and network for the given (or current) DFX_NETWORK.
snsdemo_env_name() {
  local network="${1:-${DFX_NETWORK:-local}}"
  case "$network" in
  mainnet) echo "ic" ;;
  *) echo "$network" ;;
  esac
}

# True if the current network is a local one, that is a managed network.
snsdemo_is_local() {
  case "$(snsdemo_env_name "${1:-}")" in
  local | bare) return 0 ;;
  *) return 1 ;;
  esac
}

############
# Canister IDs
############

# The file with the canister IDs that snsdemo knows about for the given network.
# The format is: { "<canister name>": "<canister ID>" }
snsdemo_ids_file() {
  echo "$SNSDEMO_STATE_DIR/canister_ids/$(snsdemo_env_name "${1:-}").json"
}

# Forgets all canister IDs of a network.
snsdemo_forget_ids() {
  rm -f "$(snsdemo_ids_file "${1:-}")"
}

# Records the ID of a canister.
# Usage: snsdemo_set_canister_id NAME ID [NETWORK]
snsdemo_set_canister_id() {
  local name="$1" id="$2" file tmp
  file="$(snsdemo_ids_file "${3:-}")"
  mkdir -p "$(dirname "$file")"
  [[ -s "$file" ]] || echo '{}' >"$file"
  tmp="$(mktemp "$file.XXXXXX")"
  jq --arg name "$name" --arg id "$id" '.[$name] = $id' "$file" >"$tmp"
  mv "$tmp" "$file"
}

# Canisters that have the same ID on the IC mainnet and in the local network.
snsdemo_well_known_canister_id() {
  case "$1" in
  nns-registry) echo "rwlgt-iiaaa-aaaaa-aaaaa-cai" ;;
  nns-governance) echo "rrkah-fqaaa-aaaaa-aaaaq-cai" ;;
  nns-ledger) echo "ryjl3-tyaaa-aaaaa-aaaba-cai" ;;
  nns-root) echo "r7inp-6aaaa-aaaaa-aaabq-cai" ;;
  nns-cycles-minting) echo "rkp4c-7iaaa-aaaaa-aaaca-cai" ;;
  nns-lifeline) echo "rno2w-sqaaa-aaaaa-aaacq-cai" ;;
  nns-genesis-token) echo "renrk-eyaaa-aaaaa-aaada-cai" ;;
  nns-identity | internet_identity) echo "rdmx6-jaaaa-aaaaa-aaadq-cai" ;;
  nns-ui | nns-dapp) echo "qoctq-giaaa-aaaaa-aaaea-cai" ;;
  nns-sns-wasm) echo "qaa6y-5yaaa-aaaaa-aaafa-cai" ;;
  nns-icp-index) echo "qhbym-qaaaa-aaaaa-aaafq-cai" ;;
  nns-cycles-ledger) echo "um5iw-rqaaa-aaaaq-qaaba-cai" ;;
  internet_identity_frontend) echo "uqzsh-gqaaa-aaaaq-qaada-cai" ;;
  sns_aggregator) echo "3r4gx-wqaaa-aaaaq-aaaia-cai" ;;
  *) return 1 ;;
  esac
}

# Prints the ID of a canister that snsdemo has recorded, if any.  Unlike
# snsdemo_canister_id, this does not know the canisters that always exist.
# Usage: snsdemo_recorded_canister_id NAME [NETWORK]
snsdemo_recorded_canister_id() {
  local file
  file="$(snsdemo_ids_file "${2:-}")"
  [[ -s "$file" ]] || return 1
  jq -er --arg name "$1" '.[$name] // empty' "$file"
}

# True if the argument looks like the ID of a canister.
snsdemo_is_canister_id() {
  [[ "$1" =~ ^[a-z2-7]{5}(-[a-z2-7]{5}){3}-cai$ ]]
}

# Prints the ID of a canister given its name or ID.
# Usage: snsdemo_canister_id NAME [NETWORK]
snsdemo_canister_id() {
  local name="$1" file id
  if snsdemo_is_canister_id "$name"; then
    echo "$name"
    return 0
  fi
  file="$(snsdemo_ids_file "${2:-}")"
  if [[ -s "$file" ]]; then
    id="$(jq -r --arg name "$name" '.[$name] // empty' "$file")"
    if [[ -n "$id" ]]; then
      echo "$id"
      return 0
    fi
  fi
  # The bare network has no NNS.
  if [[ "$(snsdemo_env_name "${2:-}")" != "bare" ]]; then
    snsdemo_well_known_canister_id "$name" && return 0
  fi
  echo "ERROR: Cannot find canister id for '$name' on network '$(snsdemo_env_name "${2:-}")'." >&2
  return 1
}

############
# Calling canisters
############

# Calls a canister (given by name or ID) on the current network.
# Without arguments, the method is called with an empty argument list, because
# icp-cli would otherwise start an interactive prompt.
# Usage: snsdemo_call CANISTER METHOD [ARGS] [icp canister call options]
snsdemo_call() {
  local id method
  id="$(snsdemo_canister_id "$1")" || return 1
  method="$2"
  shift 2
  if (($# == 0)) || [[ "$1" == -* ]]; then
    set -- "()" "$@"
  fi
  icp canister call "$id" "$method" "$@" -e "$(snsdemo_env_name)"
}

# Prints the controllers of a canister, one per line.
# Usage: snsdemo_controllers CANISTER
snsdemo_controllers() {
  local id
  id="$(snsdemo_canister_id "$1")" || return 1
  icp canister status "$id" --public --json -e "$(snsdemo_env_name)" | jq -r '.controllers[]'
}

# Prints the module hash of a canister (0x...), or nothing if there is no module.
snsdemo_module_hash() {
  local id
  id="$(snsdemo_canister_id "$1")" || return 1
  icp canister status "$id" --public --json -e "$(snsdemo_env_name)" | jq -r '.module_hash // empty'
}

############
# Identities
############

# The name of the current default identity.
snsdemo_identity() {
  icp identity default
}

# True if an identity with the given name exists.
snsdemo_identity_exists() {
  icp identity list -q | grep -qx -- "$1"
}

# Prints the path of a file with the PEM of an identity.
# Note: Direct use of the pem file is needed for ic-admin and quill.  They read
#       secp256k1 keys only in the SEC1 format ("EC PRIVATE KEY") that dfx used,
#       while icp-cli exports PKCS#8 ("PRIVATE KEY"), so the key is converted.
snsdemo_identity_pem() {
  local identity="$1" dir exported
  dir="$SNSDEMO_STATE_DIR/pem"
  mkdir -p "$dir"
  chmod 700 "$dir"
  (
    umask 077
    exported="$(mktemp "$dir/export.XXXXXX")"
    icp identity export "$identity" >"$exported"
    if ! openssl ec -in "$exported" -out "$dir/$identity.pem" 2>/dev/null; then
      # Not a secp256k1 key.  Other keys are accepted as they are.
      cp "$exported" "$dir/$identity.pem"
    fi
    rm -f "$exported"
  )
  echo "$dir/$identity.pem"
}

# The file with the IDs of the neurons of an identity, one per line.
snsdemo_neurons_file() {
  echo "$SNSDEMO_STATE_DIR/neurons/${1}.$(snsdemo_env_name "${2:-}")"
}

############
# Networks
############

# The descriptor of a running managed network, if any.
snsdemo_network_descriptor() {
  echo "$ICP_PROJECT_ROOT/.icp/cache/networks/$(snsdemo_env_name "${1:-}")/descriptor.json"
}

# The port of the gateway of a local network.
snsdemo_gateway_port() {
  local descriptor port=""
  descriptor="$(snsdemo_network_descriptor "${1:-}")"
  if [[ -s "$descriptor" ]]; then
    port="$(jq -r '.gateway.port // empty' "$descriptor")"
  fi
  echo "${port:-8080}"
}

# The URL for API calls to a network.
snsdemo_api_url() {
  local network
  network="$(snsdemo_env_name "${1:-}")"
  case "$network" in
  local | bare) echo "http://localhost:$(snsdemo_gateway_port "$network")" ;;
  ic) echo "https://icp-api.io" ;;
  *) icp network status -e "$network" --json | jq -er '.api_url' ;;
  esac
}

############
# Wasm and candid files
############

# Downloads a wasm file of a release of the IC repo, and unzips it.
# Usage: snsdemo_download_wasm IC_COMMIT REMOTE_NAME LOCAL_PATH
snsdemo_download_wasm() {
  local commit="$1" remote_name="$2" local_path="$3" url
  url="https://download.dfinity.systems/ic/$commit/canisters/${remote_name}.gz"
  echo "Getting  $local_path from $url..."
  mkdir -p "$(dirname "$local_path")"
  curl -fsSL --retry 5 --retry-all-errors --retry-delay 3 "$url" | gunzip >"$local_path"
}

# Downloads a candid file from the IC repo.
# Usage: snsdemo_download_did IC_COMMIT PATH_IN_REPO LOCAL_PATH
snsdemo_download_did() {
  local commit="$1" remote_path="$2" local_path="$3" url
  url="https://raw.githubusercontent.com/dfinity/ic/$commit/${remote_path}"
  echo "Getting  $local_path from $url..."
  mkdir -p "$(dirname "$local_path")"
  curl -sSLf --retry 5 --retry-all-errors --retry-delay 3 "$url" -o "$local_path"
}

# Checks that the wasm and candid files of canisters are present and plausible.
# Usage: snsdemo_check_imported WASM_DIR CANDID_DIR PREFIX NAME...
snsdemo_check_imported() {
  local wasm_dir="$1" candid_dir="$2" prefix="$3" name wasm did
  shift 3
  for name in "$@"; do
    wasm="$wasm_dir/$prefix$name.wasm"
    did="$candid_dir/$prefix$name.did"
    test -e "$wasm" || {
      echo "ERROR: Wasm for $prefix$name not found at '$wasm'" >&2
      return 1
    }
    file "$wasm" | grep -q wasm || {
      echo "ERROR: Wasm for $prefix$name at '$wasm' is not a wasm file." >&2
      return 1
    }
    test -e "$did" || {
      echo "ERROR: Candid for $prefix$name not found at '$did'" >&2
      return 1
    }
    grep -E '^service ' "$did" >/dev/null || {
      echo "ERROR: Candid for $prefix$name at '$did' is not a valid did file." >&2
      return 1
    }
  done
}

############
# Cycles
############

# Gives cycles to the SNS wasm canister, which pays for the canisters of new SNSs.
# The cycles are paid for with the ICP of the current identity.
snsdemo_fund_sns_wasm() {
  local environment sns_wasm
  environment="$(snsdemo_env_name "${1:-}")"
  sns_wasm="$(snsdemo_canister_id nns-sns-wasm "${1:-}")"
  icp cycles mint --cycles 180t -e "$environment" || echo "WARNING: Could not convert ICP to cycles." >&2
  icp canister top-up "$sns_wasm" --amount 180t -e "$environment" ||
    echo "WARNING: Could not give cycles to the SNS wasm canister." >&2
}

############
# Tests
############

# Starts a clean network without the NNS for a test, with an identity that is
# funded when the network starts.
snsdemo_test_network_start() {
  "$SNSDEMO_ROOT/bin/dfx-network-stop" --network bare
  snsdemo_identity_exists snsdemo-test || icp identity new snsdemo-test --storage plaintext
  icp identity default snsdemo-test
  "$SNSDEMO_ROOT/bin/dfx-network-start" --network bare
}

############
# PocketIC
############

# Converts the text representation of a principal to the hex encoded bytes.
snsdemo_principal_to_hex() {
  perl -e '
    my $s = uc $ARGV[0];
    $s =~ s/-//g;
    my $bits = "";
    for my $c (split //, $s) {
      my $i = index("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567", $c);
      die "Invalid principal: $ARGV[0]\n" if $i < 0;
      $bits .= sprintf("%05b", $i);
    }
    my $bytes = pack("B*", substr($bits, 0, int(length($bits) / 8) * 8));
    # The first 4 bytes are a checksum.
    print unpack("H*", substr($bytes, 4));
  ' "$1"
}

hex_to_base64() {
  perl -e 'print pack("H*", $ARGV[0])' "$1" | openssl base64 -A
}

# POSTs JSON to the PocketIC REST API and prints the response body.
# PocketIC answers 409 (the instance is busy with another operation, for example
# a block that auto-progress is producing) or 202 (the operation is still
# running) in which case the same request is repeated.
#
# Usage: snsdemo_pocketic_post URL JSON
snsdemo_pocketic_post() {
  local url="$1" body="$2" out code
  out="$(mktemp)"
  for _ in $(seq 1 120); do
    code="$(curl -sS -o "$out" -w '%{http_code}' -X POST -H 'Content-Type: application/json' -d "$body" "$url")" ||
      {
        rm -f "$out"
        return 1
      }
    case "$code" in
      200)
        cat "$out"
        rm -f "$out"
        return 0
        ;;
      202 | 409 | 429) sleep 0.5 ;;
      *)
        echo "PocketIC returned HTTP $code for $url: $(cat "$out")" >&2
        rm -f "$out"
        return 1
        ;;
    esac
  done
  echo "PocketIC stayed busy (HTTP $code) for $url" >&2
  rm -f "$out"
  return 1
}

# Calls a canister on a local network on behalf of any principal, without a
# signature.  This works only with PocketIC.
#
# Usage: snsdemo_pocketic_update SENDER CANISTER EFFECTIVE_CANISTER METHOD CANDID_ARGS
# EFFECTIVE_CANISTER is the canister that determines the subnet for the call.
# For calls to the management canister, that is the canister that is acted upon.
#
# Prints the response as hex.
snsdemo_pocketic_update() {
  local sender="$1" canister="$2" effective="$3" method="$4" args="$5"
  local descriptor config_port instance_id payload_hex body response message_id result
  snsdemo_require didc curl jq perl openssl
  descriptor="$(snsdemo_network_descriptor)"
  [[ -s "$descriptor" ]] || snsdemo_die "The network '$(snsdemo_env_name)' is not running."
  config_port="$(jq -er '."pocketic-config-port"' "$descriptor")" || snsdemo_die "The network '$(snsdemo_env_name)' is not a PocketIC network."
  instance_id="$(jq -er '."pocketic-instance-id"' "$descriptor")"
  payload_hex="$(didc encode "$args")"
  body="$(jq -n \
    --arg sender "$(hex_to_base64 "$(snsdemo_principal_to_hex "$sender")")" \
    --arg canister "$(hex_to_base64 "$(snsdemo_principal_to_hex "$canister")")" \
    --arg effective "$(hex_to_base64 "$(snsdemo_principal_to_hex "$effective")")" \
    --arg method "$method" \
    --arg payload "$(hex_to_base64 "$payload_hex")" \
    '{sender: $sender, canister_id: $canister, effective_principal: {CanisterId: $effective}, method: $method, payload: $payload}')"
  response="$(snsdemo_pocketic_post "http://127.0.0.1:$config_port/instances/$instance_id/update/submit_ingress_message" "$body")" || snsdemo_die "The call to $canister.$method could not be submitted."
  message_id="$(jq -ec '.Ok // empty' <<<"$response")" || snsdemo_die "PocketIC rejected the call to $canister.$method: $response"
  [[ -n "$message_id" ]] || snsdemo_die "PocketIC rejected the call to $canister.$method: $response"
  response="$(snsdemo_pocketic_post "http://127.0.0.1:$config_port/instances/$instance_id/update/await_ingress_message" "$message_id")" || snsdemo_die "The call to $canister.$method could not be awaited."
  result="$(jq -r '.Ok // empty' <<<"$response")"
  [[ -n "$result" ]] || snsdemo_die "The call to $canister.$method failed: $response"
  openssl base64 -d -A <<<"$result" | od -An -tx1 | tr -d ' \n'
}
