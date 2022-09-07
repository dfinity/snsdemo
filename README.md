# Local NNS and SNS

Welcome to the world of the Network Nervous System.  In this tutorial we will show you how to deploy the NNS locally and how you can decentralize your dapp using the SNS.

## Setup
Clone this project:
```bash
git clone https://github.com/dfinity/snsdemo.git
cd snsdemo
```
Let's remember this location, and use the included tools:
```bash
export SNSDEMO="$PWD"
export PATH="$SNSDEMO/bin:$PATH"
```

## Install dfx
This dfx functionality has not been released yet, so you will need a special build, which you can obtain as follows:
```bash
git clone https://github.com/dfinity/sdk.git
pushd sdk
command -v cargo || echo "Please install rust before proceeding: https://www.rust-lang.org/tools/install"
cargo build
cp target/debug/dfx "$SNSDEMO/bin/"
```
Now we should now be able to see the help pages for the NNS commands:
```bash
dfx nns --help
dfx nns install --help
dfx nns import --help
```




```bash
cd snsdemo/
dfx help
dfx config --help
```
