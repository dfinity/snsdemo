# SNS DEMO

This repository has a collection of tools to make it easier to manage
environments with SNS projects and other dependencies. If this sounds vague it's
because it's a bit of a kitchen sink. Some of them are described below.

The official documentation for SNS testing has moved [here](https://github.com/dfinity/sns-testing).

## Stock snapshot

A snapshot is an archive (`.tar.xz`) containing local replica state.

### Manual use

A stock snapshot can be created with
```
./bin/dfx-snapshot-stock-make
```
Snapshots can be shared between Linux machines but Macs can only use snapshots
created on the same machine (it seems).

Default pinned versions of the used canisters are defined in
`bin/versions.bash`. If you want the latest versions on the canisters from the
IC repo, you can run
```
./bin/dfx-snapshot-stock-make --ic_commit latest --ic_dir $YOUR_IC_REPO_PATH
```
The IC repo directory is needed to find the latest usable commit. You can also
specify a specific commit instead of `latest` and then you don't need to specify
`--ic_dir`.

If you want to customize what is included in the snapshot, you can modify
`bin/dfx-stock-deploy`.

The SNSes that are being deployed are configure with `sns_init.yaml` as well as
the parameters passed to `ic-admin` from `bin/dfx-sns-sale-propose`.

### CI

A new stock snapshot can be released by running the
[Create a snapshot image workflow](https://github.com/dfinity/snsdemo/actions/workflows/snapshot.yml)
and checking the "Make release" box.

This will cause GitHub actions to create a new snapshot, which can be found
[here](https://github.com/dfinity/snsdemo/tags).



## Creating an SNS in GitHub CI

Please see [the GitHub workflow that tests SNS creation on Linux and Mac](.github/workflows/run.yml).
