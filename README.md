# Local NNS and SNS

Welcome to the world of the Network Nervous System.  In this tutorial we will show you how to deploy the NNS locally and how you can decentralize your dapp using the SNS.

## Setup
Clone this project:
<!---
The comments like this are not displayed in Markdown; they contain code for automated testing.
```bash
# We will use the current directory for testing, but make sure it is clean.
if false ; then
```
-->
```bash
git clone https://github.com/dfinity/snsdemo.git
cd snsdemo
```
<!---
```bash
else
  git clean -dfx
  dfx stop || true
  pkill dfx || true
  pkill icx-proxy || true
fi
```

```bash
if false ; then # skip first deployment
```
-->

## Project contents
Before we get started, let's have a quick look at this repo.  It contains a simple toy application and some scripts to help you through this tutorial.  Have a look at dfx.json and the src directory.  Then let's deploy it:

```bash
: Start the server
dfx start --host 127.0.0.1:8080 --background
sleep 2
: If we ask, we should be awarded a starting balance to play with.
dfx wallet balance
: Now we can build and deploy the dapp:
npm ci
dfx deploy
echo http://$(dfx canister id smiley_dapp_assets).localhost:8080
```
<!---
```bash
say Smiley deployed
read -rp "Click the link and check that you see the clock or smiley. OK?  "
```
-->

Open the URL printed by that last line and you should see the smiley dapp:

![image](docs/images/smiley.png)

After this tutorial is complete we hope that you will experiment using the same commands with your own projects.

## Install dfx
This dfx functionality has not been released yet, so you will need a special build, which you can obtain as follows:
<!---
```bash
fi # Skip first deployment
```
```bash
dfx cache list 2>&1 | grep -q "$(../sdk/target/debug/dfx --version | awk '{print $2}' || echo "UNDEFINED")" || {
```
-->
This dfx functionality has not been released yet, so you will need a special build, which you can obtain as follows:
 ```bash
pushd ..
test -d sdk || git clone https://github.com/dfinity/sdk.git
pushd sdk
git fetch
git checkout tutorial2
git reset --hard origin/tutorial2
command -v cargo || echo "Please install rust before proceeding: https://www.rust-lang.org/tools/install"
cargo build
export DFX_WARNING=-version_check
export DFX_VERSION="$(./target/debug/dfx --version | awk '{print $2}')"
popd
popd
```
<!---
```bash
}
```
-->

Note that the above does not change your default dfx.  To use the custom dfx locally we need to specify it in dfx.json:
```bash
pwd
jq '.dfx=(env.DFX_VERSION)' dfx.json | sponge dfx.json
cat dfx.json
dfx cache list | grep -qw "$DFX_VERSION" || ../sdk/target/debug/dfx cache install
echo OK
```

And:
```bash
cp "$HOME/.cache/dfinity/versions/$DFX_VERSION/sns" ./bin/
```

Now we should now be able to see the help pages for the NNS commands:
```bash
dfx nns --help
dfx nns install --help
dfx nns import --help
```

## Start a local testnet
Make sure that your `$HOME/.config/dfx/networks.json` has the following configuration for the "local" network:
<!---
```bash
mv "$HOME/.config/dfx/networks.json" "$HOME/.config/dfx/networks.json.$(date +%s)"
cat <<EOF>"$HOME/.config/dfx/networks.json"
```
-->
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
<!---
```bash
EOF
```
-->
Note:
* The "old" method of configuring networks is in `dfx.json`.  The old method is deprecated but still works and
  will be supported until Spring 2023.  The above is equivalent to including this in your `dfx.json`:
  ```
  {
    "networks": {
        "local": {
            "bind": "127.0.0.1:8080",
            "type": "ephemeral",
            "replica": {
                "subnet_type": "system"
            }
        }
    }
  }
  ```

Now you can start your local testnet:
```bash
dfx stop
nohup dfx start --clean --host 127.0.0.1:8080 --background &
sleep 10
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
<!---
```bash
say NNS dapp setup
read -rp "Log in to the nns and check that the launchpad is there. OK?  "
read -rp "Create a neuron with 500M ICP and an 8 year dissolve delay. OK?  "
```
-->

You should see something like this:

![image](docs/images/dfx-nns-install-head.png)

SNIP

![image](docs/images/dfx-nns-install-tail.png)

Let's see what we have.

### Internet Identity
Click on the `internet_identity` URL printed in the terminal.  This is a login service for dapps, similar to "login with google" but without the advertising.  Check that you can create an identity and log in.  You won't see much after you have logged in but you will have an identity that you can use on your testnet.

The local installation differs from production to make it more useful for automated testing.
* The captcha is always "a".
* No hardware key is needed to log in.
This is of course tremendously insecure but very useful for testing.

If you wish, you can add a login service to the toy dapp using `internet_identity`.

### NNS Dapp
Click on the `nns-dapp` URL.  You should be able to log in with your new identity.

The NNS Dapp acts as a wallet.  You will need toy ICP tokens to test with.  Note that at the bottom of the menu there is a "Get ICPs" button with which you can award yourself ICP.  Free ICP are limited but you can make yourself a millionaire.

To be able to make decisions in your local testnet you will need a neuron with hefty voting power.  In the real world, neuron ownership is distributed but in the testnet, if you make yourself a neuron with 500 million ICP and an 8 year dissolve delay you will be able to vote through proposals under almost any circumstances.

Finally, look to see what proposals you can vote on.  Disappointingly, if you look at the voting tab you will see no proposals but, actually, setting up the local NNS involved passing some proposals.  You can see this if you filter by proposal status == executed and select all topics.  You will be able to make proposals locally and vote on them.

### Import did files
To interact with the back end governance canisters you will need the API definitions.  So far the commands have not altered the local project at all, but now we will add information about the NNS and SNS to the local project:
```bash
dfx nns import
dfx sns import
: The above are not complete so you will temporarily also need:
cat <<<"$(jq '.canisters["nns-sns-wasm"].remote.id.local = "qjdve-lqaaa-aaaaa-aaaeq-cai"' dfx.json)" > dfx.json
cat <<<"$(jq '.canisters["nns-governance"].remote.id.local = "rrkah-fqaaa-aaaaa-aaaaq-cai"' dfx.json)" > dfx.json
```
You look in your dfx.json you should see the NNS canisters listed and you should have did files.  For example:
```bash
jq '.canisters["nns-sns-wasm"]' dfx.json
ls candid/nns-sns-wasm.did
```

## Decentralize the Smiley Dapp
Now we will hand over control of the local Smiley Dapp to the community; the community of just you, the reader, but the process is the same for handing over control of a real dapp on mainnet to the community at large.

### Redeploy the smiley dapp
We deployed the smiley dapp before but then wiped the network.  Let's recreate it:
```bash
npm ci
dfx deploy --with-cycles 1000000000000 smiley_dapp
dfx deploy --with-cycles 1000000000000 smiley_dapp_assets
```
TODO: Can we just use `dfx deploy` here?   The other canisters SHOULD not be deployed; they are remote, right?
TODO: Can we print the subdomain-based canister URLs please?

### Configure an SNS
You will need to decide some things such as token name and token parameters.  To do this:
```bash
./bin/sns init-config-file new
```
TODO: This should print the location of the file it has created.

This will create a configuration file:
```bash
ls sns_init.yaml
```
Open it in an editor.  You will see some blanks that need to be filled in with your SNS parameters.  Fill them in.

You can check whether your entries are complete and valid by running:
<!---
```bash
# The validation is expected to fail.  Validation is exercised soon though...
if false ; then
```
-->
```bash
./bin/sns init-config-file validate
```
<!---
```bash
fi
```
-->
If you just want a random config that works, run:
```bash
./bin/sns-configure-random
./bin/sns init-config-file validate
```

### Create an SNS
Creating an SNS is expensive; the price is set at 50 trillion cycles.  Make sure that your wallet has at least that much:
```bash
dfx wallet balance
```
If you need more, you can buy yourself some in the canisters tab of the NNS UI, by adding your wallet canister and sending it cycles.

Now, you can deploy:
```bash
./bin/sns deploy --init-config-file sns_init.yaml
: As sns is not integrated into dfx we need to do this as well:
cat <<<"$(jq -s '.[0] * .[1]' .dfx/local/canister_ids.json  canister_ids.json)" > .dfx/local/canister_ids.json
```

Visit
<!---
TODO:
- Refuse to do `bin/sns deploy` unless the sns did files are installed.
- Likewise refuse if the canister ID is not defined.
- Add the local NNS canister IDs are remotes?
- Then the canister IDs could be added as remotes?  Maybe refuse to proceed if there are already remotes in place?
- What if the local did files are out of date/out of sync with prod?  Prod could differ from the local environment.
-->

```bash
jq '.canisters' dfx.json | grep sns_
```

Your wallet will also feel a lot lighter:
```bash
dfx wallet balance
```

### Hand over control
You are the current controller of the smiley dapp.  You can check that like this:
```bash
dfx canister info smiley_dapp
```
The controller should match your identity:
```bash
dfx identity get-principal
```

You need to transfer control of the smiley face canisters to the SNS.
```bash
./bin/sns-handover
```

Now compare the canister controller with the SNS root.  You should find that they are the same:
```bash
dfx canister id sns_root
dfx canister info smiley_dapp
```

### Neurons
In the NNS UI, make sure that you have a large neuron so that you can pass proposals; it represents the voting public.  If you created large neuron earlier that will suffice.

You will also need a small neuron to represent yourself, the developer.  5 ICP should suffice and the dissolve delay can be zero.  You will also need to add your principal as a hotkey to this developer neuron.  Here is how to do this:

Create the neuron:
<!---
```bash
say Create a developer neuron
read -rp "Create a small neuron,  OK?"
```
-->
- Log in to the nns-dapp: <http://qhbym-qaaaa-aaaaa-aaafq-cai.localhost:8080/>
- Make sure that you have at least 5 ICP in your main account; if not get more with the "Get ICP" menu entry.
- Go to the neurons tab and create a neuron.  Give it 5 ICP and an 8 year dissolve delay.
- Make a note of your neuron ID:
  ```bash
  read -rp "What is your developer neuron ID?  " DEVELOPER_NEURON_ID
  echo DEVELOPER_NEURON_ID=$DEVELOPER_NEURON_ID >> .demo-env
  ```

Add your principal as a hotkey:
- Get your command line principal:
  ```bash
  dfx identity get-principal
  ```
- In the nns-dapp, click on your neuron to see the neuron details.
- Scroll down to "Hotkeys" and add your command line principal as a hotkey.

<!---
```bash
say NNS dapp setup
read -rp "Add this as a hotkey to the developer neuron: $(dfx identity get-principal)   OK?"
```
-->



### Propose to start the SNS
The community takes some responsibility for which SNS's are created, so it gets to vote on the creation:

<!---
```bash
{
```
-->
```bash
bin/dfx-sns-swap-start --title "$USER $(date +'%Y%m%dT%H%M')" --proposer "$DEVELOPER_NEURON_ID"
```
<!---
```bash
} > ,start-swap.idl
PROPOSAL_ID="$(idl2json <,start-swap.idl | jq -r '.command[0].MakeProposal.proposal_id[0].id')"
read -rp "Vote for the proposal $PROPOSAL_ID OK?  "
```
-->

In the NNS Dapp UI go to the launchpad.

You should see a proposal.
* You may need to refresh

Vote for the proposal to pass.  As you have a huge neuron - your private network is not decentralized - your vote should be enough to pass the proposal.  If you watch the top of the proposal status, it should change to "Executed" after no more than 30 seconds.

### Invest
Return to the launchpad and hit refresh.  You should now see the SNS move into the "Current Launches" section.  If you click on it, you will be able to read details about the project.

Note the sale start time.  Wait until then, then hit refresh.  You should now see an interface to buy SNS tokens.  If yo don't, run this:
```bash
dfx canister call sns_swap refresh_sns_tokens '(record {})'
```

Buy some tokens.  The sale will be complete when either the maximum investment has been reached or the sale end time is reached.  If you use the default SNS configuration you can buy all 50 ICP.  This is convenient for testing but in a real SNS you may wish to limit the stake so that no investor has excessive influence over the project.

<!---
```bash
read -rp "Invest 50 ICP.  OK?  "
```
-->

### Finalize the swap
```bash
bin/sns-finalize-swap
```
