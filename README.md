# SNS DEMO

This repository has a collection of tools to make it easier to manage
environments with SNS projects and other dependencies. If this sounds vague it's
because it's a bit of a kitchen sync. Some of them are described below.


The official documentation for SNS testing has moved [here](https://internetcomputer.org/docs/current/developer-docs/integrations/sns/get-sns/local-testing).

## Stock snapshot

A snapshot is an archive (`.tar.xz`) containing local replica state.

### Manual use

A stock snapshot can be created with `./bin/dfx-snapshot-stock-make`. Snapshots
can be shared between Linux machines but Macs can only use snapshots created on
the same machine (it seems).

### CI

A new stock snapshot can be released by pushing a tag:

```
git tag -a release-2013-45-56 -m "The new release"
git push origin release-2013-45-56
```

This will cause GitHub actions to create a new snapshot, which can be found
[here](https://github.com/dfinity/snsdemo/tags).



## Creating an SNS in GitHub CI

Please see [the GitHub workflow that tests SNS creation on Linux and Mac](.github/workflows/run.yml).
