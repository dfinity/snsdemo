# SNS DEMO

This repository has a collection of tools to make it easier to manage
environments with SNS projects and other dependencies. If this sounds vague it's
because it's a bit of a kitchen sink. Some of them are described below.

The official documentation for SNS testing has moved [here](https://github.com/dfinity/sns-testing).

## Setup

The tools are installed with [mise](https://mise.jdx.dev):
```
mise install
```
This installs [icp-cli](https://github.com/dfinity/icp-cli) (which replaces the
deprecated `dfx`), the network launcher that contains PocketIC, `quill`,
`idl2json`, `didc` and `ic-wasm`, in the versions that are pinned in
`mise.toml`. `bin/dfx-sns-demo-install` does that and also installs the
remaining prerequisites (`jq`, `sponge` and `openssl`) and the `ic-admin` and
`sns` executables from the IC commit in `bin/versions.bash`.

The scripts are still called `dfx-*` so that existing tooling and muscle memory
keep working. Internally they use `icp`.

## Local networks

The local networks are defined in `icp.yaml`:
 * `local` is a network with the NNS, the SNS wasm canister, Internet Identity,
   the NNS dapp and the SNS aggregator. PocketIC installs these canisters, with
   the same canister IDs as on the IC mainnet. The versions of the canisters
   are those of the network launcher in `mise.toml`, so updating the launcher
   updates the NNS.
 * `bare` is a network without the NNS, used in tests.

Start and stop a network with
```
./bin/dfx-network-start
./bin/dfx-network-stop
```
Local networks start empty every time. Identities that exist when a network
starts are given ICP and cycles, so create identities before you start the
network. The `anonymous` identity is the one with a lot of ICP, from which
`bin/dfx-ledger-get-icp` gives ICP to other identities.

`snsdemo` remembers the canister IDs and neurons that it creates in
`.snsdemo/`. Use `bin/dfx-canister-id NAME` to look up a canister ID.

## Stock snapshot

A snapshot is an archive (`.tar.xz`) containing local replica state.
Snapshots can be restored only with the same version of the network launcher
that created them. Snapshots made with `dfx` can not be restored.

### Manual use

A stock snapshot can be created with
```
./bin/dfx-snapshot-stock-make
```
A snapshot can be restored with
```
./bin/dfx-snapshot-restore --snapshot stock-snsdemo-snapshot.tar.xz
```
Snapshots can be shared between Linux machines but Macs can only use snapshots
created on the same machine (it seems).

Default pinned versions of the canisters that snsdemo installs itself, such as
the ckBTC canisters, are defined in `bin/versions.bash`. If you want the latest
versions of those canisters from the IC repo, you can run
```
./bin/dfx-snapshot-stock-make --ic_commit latest --ic_dir $YOUR_IC_REPO_PATH
```
The IC repo directory is needed to find the latest usable commit. You can also
specify a specific commit instead of `latest` and then you don't need to specify
`--ic_dir`. The NNS canisters are not affected by this: they come from the
network launcher.

If you want to customize what is included in the snapshot, you can modify
`bin/dfx-stock-deploy`.

The SNSes that are being deployed are configured with `bin/sns_init.yaml`.

### CI

A new stock snapshot can be released by running the
[Create a snapshot image workflow](https://github.com/dfinity/snsdemo/actions/workflows/snapshot.yml)
and checking the "Make release" box.

This will cause GitHub actions to create a new snapshot, which can be found
[here](https://github.com/dfinity/snsdemo/tags).



## Creating an SNS in GitHub CI

Please see [the GitHub workflow that tests SNS creation on Linux and Mac](.github/workflows/run.yml).
