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

## Project contents
Before we get started, let's have a quick look at this repo.  It contains a simple toy application and some scripts to help you through this tutorial.  Have a look at dfx.json and the src directory.  If you wish, you can have a look at the toy dapp:

```bash
dfx start --background
dfx deploy
echo http://$(dfx canister id smiley_dapp_assets).localhost:8080
```
Open the URL printed by that last line and you should see the smiley dapp:

![image](docs/images/smiley.png)

After this turorial is complete we hope that you will experiment using the same commands with your own projects.

## Install dfx
This dfx functionality has not been released yet, so you will need a special build, which you can obtain as follows:
```bash
git clone https://github.com/dfinity/sdk.git
pushd sdk
command -v cargo || echo "Please install rust before proceeding: https://www.rust-lang.org/tools/install"
cargo build
cp target/debug/dfx "$SNSDEMO/bin/"
popd
```
Also, to use the non-production build, it is important to remove the `dfx` version from `dfx.json`, otherwise your calls to dfx will simply be redirected to a normal production build and new functionality will not work.  You can do this with:
```
cat <<<$(jq 'del(.dfx)' dfx.json.original) >dfx.json
```

Now we should now be able to see the help pages for the NNS commands:
```bash
dfx nns --help
dfx nns install --help
dfx nns import --help
```

## Start a local testnet
Make sure that your `$HOME/.config/dfx/networks.json` has the following configuration for the "local" network:
```bash
{
  "local": {
    "bind": "127.0.0.1:8080",
    "type": "ephemeral",
    "replica": {
      "subnet_type": "system"
    }
  }
}
```
Now you can start your local testnet:
```bash
dfx start --clean --background
```
You should see something like this:

![image](docs/images/dfx-start-clean.png)

Some things to note:
* The `--clean` flag is important, as system canisters have pre-assigned canister IDs that must be vacant before we install them.
* In the output, see the line "subnet type: System".  This confirms that our configuration has taken effect.
* Note the dashboard URL at the end of the output.  Open it in a browser.  It should show that there are no canisters currently installed.  Keep this page open; as the tutorial progresses you will be able to see canisters being installed.

  ![image](docs/images/dashboard-empty.png)

## Install NNS canisters
The NNS is the decentralization mechanism for the Internet Computer.  Normally it is run on many computers and the only way of making changes to it is by submitting proposals and letting neuron holders vote on the proposals.  For you to be able to experiment by yourself, we will install a test version that allows you to make changes locally by yourself. 

```bash
dfx nns install
```

You should see something like this:

![image](docs/images/dfx-nns-install-head.png)

SNIP

![image](docs/images/dfx-nns-install-tail.png)