var OpMan = artifacts.require("./OpMan/OpMan.sol");

/* djh??
// To be changed to deploy all the contracts, recording their addresses, then to call the Initialise() functions.

Contracts
=========
Contract  Description                                                Owned By                         External Calls
--------  -----------                                                --------                         --------------
OpMan     Operations management - multisig approval of critical ops  Deployer, Self,  Admin           All including self
Hub       Hub or management contract                                 Deployer, OpMan, Admin, Sale     OpMan; Sale; Token; List; Escrow; Grey; VoteTap; VoteEnd; Mvp
Sale      Sale                                                       Deployer, OpMan, Hub             OpMan; Hub -> Token,List,Escrow,Grey,VoteTap,VoteEnd,Mvp; List; Token -> List; Escrow; Grey
Token     Token contract with EIP-20 functions                       Deployer, OpMan, Hub, Sale, Mvp  OpMan; List
List      List of participants                                       Deployer, OpMan, Hub, Token      OpMan
Escrow    Escrow management of funds from whitelisted participants   Deployer, OpMan, Hub, Sale       OpMan
Grey      Escrow management of funds from grey list participants     Deployer, OpMan, Hub, Sale       OpMan
VoteTap   For a tap vote                                             Deployer, OpMan, Hub             OpMan; Hub -> Escrow, List
VoteEnd   For a terminate and refund vote                            Deployer, OpMan, Hub             OpMan; Hub -> Escrow, List
Mvp       Re MVP launch and transferring PIOEs to PIOs               Deployer, OpMan, Hub             OpMan; List; Token -> List

where Admin is a PCL hardware wallet

Initialisation and Deployment
#############################
Contracts can be constructed and deployed in any order with contract addresses being recorded by the script.

Then:

OpMan owned by 0 Deployer, 1 OpMan (self), 2 Admin
-----
OpMan.ChangeOwnerMO(ADMIN_OWNER_X, PCL hw wallet account address as Admin)
OpMan.Initialise(address[] vContractsYA, address[] vSignersYA) IsInitialising
  to set initial contracts, signers, and add the OpMan manOps
  After this call all of OpMan's owners are set.
  Arguments:
  - vContractsYA  Array of contract addresses for Hub, Sale, Token, List, Escrow, Grey, VoteTap, VoteEnd, Mvp in that order. Note, NOT OpMan which the fn uses this for.
  - vSignersYA    Array of the addresses of the initial signers. These will need to be confirmed before they can be used for granting approvals.

Hub owned by 0 Deployer, 1 OpMan, 2 Admin, 3 Sale
---
Hub.ChangeOwnerMO(OP_MAN_OWNER_X, OpMan address)
Hub.ChangeOwnerMO(ADMIN_OWNER_X, PCL hw wallet account address as Admin)
Hub.ChangeOwnerMO(SALE_OWNER_X, Sale address)
Hub.ChangeOwnerMO(WEB_OWNER_X, Web account address)
Hub.Initialise() to set the contract address variables.
Hub.SetCapsAndTranches(uint256 vPicosCapT1, uint256 vPicosCapT2, uint256 vPicosCapT3, uint256 vUsdSoftCap, uint256 vUsdHardCap,
                       uint256 vMinWeiT1, uint256 vMinWeiT2, uint256 vMinWeiT3, uint256 vPriceCCentsT1, uint256 vPriceCCentsT2, uint256 vPriceCCentsT3)
Hub.SetUsdEtherPrice(uint256 vUsdEtherPrice) - Requires IsAdminCaller which will pass if called by the deploy script before the owners are set.
Hub.SetPclAccount(address vPclAccountA) external
Hub.EndInitialise() to end initialising

Sale owned by 0 Deployer, 1 OpMan, 2 Hub
----
Sale.ChangeOwnerMO(OP_MAN_OWNER_X, OpMan address)
Sale.ChangeOwnerMO(HUB_OWNER_X, Hub address)
Sale.Initialise()  to set the contract address variables.

List owned by 0 Deployer, 1 OpMan, 2 Hub, 3 Token
----
List.ChangeOwnerMO(OP_MAN_OWNER_X OpMan address)
List.ChangeOwnerMO(HUB_OWNER_X, Hub address)
List.ChangeOwnerMO(TOKEN_OWNER_X, Token address)
List.Initialise()  to set the contract address variables.

Token owned by 0 Deployer, 1 OpMan, 2 Hub, 3 Sale, 4 Mvp
-----
Token.ChangeOwnerMO(OP_MAN_OWNER_X, OpMan address)
Token.ChangeOwnerMO(HUB_OWNER_X, Hub address)
Token.ChangeOwnerMO(SALE_OWNER_X, Sale address)
Token.ChangeOwnerMO(MVP_OWNER_X, Mvp address)
Token.Initialise() To set the contract variable, and do the PIOE minting.

Escrow owned by Deployer, OpMan, Hub, Sale
------
Escrow.ChangeOwnerMO(OP_MAN_OWNER_X OpMan address)
Escrow.ChangeOwnerMO(HUB_OWNER_X, Hub address)
Escrow.ChangeOwnerMO(SALE_OWNER_X, Sale address)
Escrow.Initialise() to initialise the Escrow contract

Grey owned by 0 Deployer, 1 OpMan, 2 Hub, 3 Sale
----
Grey.ChangeOwnerMO(OP_MAN_OWNER_X OpMan address)
Grey.ChangeOwnerMO(HUB_OWNER_X, Hub address)
Grey.ChangeOwnerMO(SALE_OWNER_X, Sale address)
Grey.Initialise() to initialise the Grey contract

VoteTap owned by 0 Deployer, 1 OpMan, 2 Hub
-------
VoteTap.ChangeOwnerMO(OP_MAN_OWNER_X OpMan address)
VoteTap.ChangeOwnerMO(HUB_OWNER_X, Hub address)
VoteTap.Initialise() to initialise the VoteTap contract

VoteEnd owned by 0 Deployer, 1 OpMan, 2 Hub
-------
VoteEnd.ChangeOwnerMO(OP_MAN_OWNER_X OpMan address)
VoteEnd.ChangeOwnerMO(HUB_OWNER_X, Hub address)
VoteEnd.Initialise() to initialise the VoteEnd contract

Mvp owned by 0 Deployer, 1 OpMan, 2 Hub
---
Mvp.ChangeOwnerMO(OP_MAN_OWNER_X OpMan address)
Mvp.ChangeOwnerMO(HUB_OWNER_X, Hub address)
Mvp.Initialise() to initialise the Mvp contract

Then Manually by Admin
----------------------
Hub.PresaleIssue() for all aggregated Seed Presale and Private Placement contributors
...
Hub.StartSale()

*/

module.exports = function(deployer) {
 console.log('Creating OpMan');
           // constructor(address[] vContractsYA, address[] vSignersYA) internal {
//deployer.deploy(OpMan, ['0x324D03c986917483cE053Cd647e697e8917399bC', '0x324D03c986917483cE053Cd647e697e8917399b2'], ['0x324D03c986917483cE053Cd647e697e8917399bC', '0x324D03c986917483cE053Cd647e697e8917399b3'], {gas:7300000});
  deployer.deploy(OpMan);
};

/*
// Spec: In Truffle, create a migration script that calls the CreateProject function after FundingHub has been deployed.

var FundingHub = artifacts.require("./FundingHub.sol");

module.exports = function(deployer) {
  deployer.deploy(FundingHub)
  .then(function() {
    return FundingHub.deployed()
  }).then(instance => {
    console.log('Creating first project');
    let nowT = new Date(), // now UTC
    deadlineSecs = nowT.getTime()/1000.0 + 3600; // 1 hour from now
    // console.log('nowT', nowT);
    // console.log('deadline secs', deadlineSecs);
    // from needs to be FundingHub owner which will be web3.eth.accounts[0]
    // Make project owner web3.eth.accounts[1]
    // function CreateProject(bytes32 vNameS, address vOwnerA, uint vTargetWei, uint vDeadlineT) FHisActiveAndSenderIsOk IsOwner returns (uint Id) {
    // console.log('CreateProject("First Project via Migrate",'+ web3.eth.accounts[1]+', '+web3.toWei(11, "ether")+', '+deadlineSecs+', '+'{from: '+web3.eth.accounts[0]+', +gas: '+1000000+'})');
    return instance.CreateProject("First Project via Migrate", web3.eth.accounts[1], web3.toWei(11, "ether"), deadlineSecs, {from: web3.eth.accounts[0], gas: 1100000});
  })
  .then(txObj => {
    console.log("First project added. Gas used", txObj.receipt.gasUsed); // 1068241
  }).catch(e => console.log('Error creating initial project in migration script', e));
};
*/
