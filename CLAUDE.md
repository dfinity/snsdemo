# CLAUDE.md

## What this is

`snsdemo` is a collection of bash scripts that set up local networks with the
NNS and SNS projects, for demos, tests and snapshots. The scripts are in
`bin/`. They are named `dfx-*` for historical reasons; they use `icp-cli`
(the `icp` command), not `dfx`, which is deprecated.

## Tools

 * Tools are installed with `mise install`, see `mise.toml`. Versions of
   `icp-cli` and of the network launcher (PocketIC) are pinned there.
 * `ic-admin` and `sns` are downloaded for the IC commit in `bin/versions.bash`.
 * `jq`, `sponge`, `openssl`, `perl`, `curl` and `gh` come from the system.

## Layout and conventions

 * `icp.yaml` defines the networks (`local` with the NNS, `bare` without) and the
   mock canisters that icp-cli deploys itself (`icp-swap`, `kong-swap`).
 * `bin/snsdemo.bash` is a library that scripts `source`. It has the helpers for
   canister IDs, identities, PEM files and the PocketIC REST API. Put shared
   code there.
 * Every script uses `bin/clap.bash` for options, with `DFX_NETWORK` as the
   network variable. `--help` is generated from the `clap.define` lines.
 * `snsdemo` keeps its state in `.snsdemo/` (canister IDs in
   `canister_ids/<network>.json`, neuron IDs in `neurons/`, exported PEM files in
   `pem/`). It is not in git. `SNSDEMO_STATE_DIR` overrides the location.
 * Numbers in Candid arguments for `icp canister install` need type
   annotations, such as `opt (12 : nat32)`, because icp-cli does not know the
   types.
 * Tests are the scripts named `*.test`; CI runs them from `.github/workflows/checks.yml`.
 * `bin/dfx-shim/dfx` is a stand-in for `dfx` for the `sns` command line tool,
   which calls `dfx`. Only the commands that `sns` uses are supported.
 * Local networks start with an empty state, because icp-cli deletes it.
   `bin/dfx-snapshot-restore` works around that with `bin/dfx-snapshot-launcher`.

## Checks

 * `scripts/lint-sh` runs ShellCheck. `scripts/fmt-sh` formats with `shfmt -i 2`.
 * `bin/clap.test` and the other `*.test` scripts run the tests. Tests that start
   a network need `mise install` first.

## Things to know

 * PocketIC installs the NNS, so the system canisters have the same IDs as on
   mainnet. See `snsdemo_well_known_canister_id` in `bin/snsdemo.bash`.
 * To act as a canister controller without being one, `bin/dfx-add-controller`
   calls the management canister as the existing controller through the PocketIC
   REST API. That works only on local networks.
 * The `anonymous` principal holds the ICP of a new local network.
   `bin/dfx-ledger-get-icp` transfers from it.
