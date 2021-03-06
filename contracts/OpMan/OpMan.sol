
/* OpMan\OpMan.sol

OpMan is the Operations Manager for the Pacio DAICO with Multisig signing required to approve critical operations, called 'managed ops' or manOps.

djh??
• Add more arguments to the ofline signing for approvaing a MO

All contracts, including OpMan, should use managed ops for:
- ownership changes
- any administrator type operations

Owners: Deployer OpMan (self) Hub Admin
------
0 Deployer
1 OpMan (self)  - Set by OwnedOpMan.sol constructor
2 & 3 Hub and Admin - Set by deploy script

OpMan Processes
---------------
1. Add contracts, signers, and manOps via the Initialise() method to be called from the deploy script
2. Admin to add additional signer as a managed op
3. Admin to change one signer to another as a managed op
4. Signer:
   4.1 Signer to confirm self as a signer
   4.2 Admin to unconfirm (pause) a signer
5. Admin to update a manOp as a managed op
6. Offline signatures to be submitted to approve a manOp
7. Approve or reject a request by a contract function to perform a managed op
8. Pause contract and ops
   8.1 Hub call or Signer to pause a contract, with a call to the contract's Pause() fn if the contract has one. Not a managed op.
   8.2 Signer to pause a manOp. Not a managed op.
9. Resume contract and ops as managed ops
   9.1 Signer to resume a contract as a managed op with a call to the contract's ResumeMO() fn if the contract has one
   9.2 Signer to resume a manOp as a managed op

Pause/Resume
============
OpMan.PauseContract(OPMAN_CONTRACT_X) IsHubContractCallerOrConfirmedSigner
OpMan.ResumeContractMO(OPMAN_CONTRACT_X) IsConfirmedSigner which is a managed op

*/

pragma solidity ^0.4.24;

import "../lib/I_Owned.sol";
import "../lib/OwnedOpMan.sol";

contract OpMan is OwnedOpMan {
  // OpMan specific constants
  uint32 private constant MIN_NUM_SIGNERS = 3;

  struct R_Contract {   // for the array of contracts pContractsYR
    address contractA;  // *
    bool    pausableB;  // * true if contract is pausable i.e. that the contract has a SetPause(bool B) function
    bool    pausedB;    // * true if contract is paused
    uint32  addedT;     //
    uint32  updatedT;   // *
    uint32  numManOps;  // * number of manOps
    mapping (uint256
    => bool) manOpsOpxMB;// * To confirm ownership of manOps by contract
  }                      // |- * = can be updated via a managed op

  struct R_Signer {    // for the pSignersAddrMR mapping keyed by signer address. The address of a signer is also held in pSignersYA
    uint32 addedT;
    uint32 confirmedT; // set when a signer is confirmed
    uint32 numSigs;    // /- updated when signer approves an op
    uint32 lastSigT;   // |
  }

  struct R_ManOp {
    uint32 contractX;    // index of the contract with the operation to be approved
    uint32 sigsRequired; // number of signatures required
    uint32 secsValid;    // secs in which signing is to be completed and the approval used
    uint32 approvedT;    // time at which the op was approved
    uint32 approvals;    // number of times the manOp has been approved or used
    bool   approvedB;    // true when op is approved, false when approval has been used
    bool   pausedB;      // true if manOP is paused
  }

  // Storage
  R_Contract[] private pContractsYR;                    // Array of the contracts
  mapping(address => uint256) private pContractsAddrMX; // Mapping of contracts by address -> cX (contract index in pContractsYR)
  mapping(uint256 => R_ManOp) private pManOpsOpkMR;     // mapping of  manOps by key manOpK = cX * 100 + manOpX keys so that opXs can repeat i.e. RESUME_CONTRACT_MO_X for all Pausible contracts
  uint256[] private pManOpKsYU;                         // Array of the manOps mapping keys manOpK = cX * 100 + manOpX
  mapping(address => R_Signer) private pSignersAddrMR;  // Mapping of the signers keyed by address
  address[] private pSignersYA;                         // Array of the signers to allow a traverse of pSignersAddrMR
  uint256   private pNOnce;                             // nonce for ManOp approvals. No view fn for this.

  // Events
  // ======
  event InitialiseV(address Deployer);
  event AddContractV(uint256 ContractX, address ContractA, bool Pausable);
  event AddSignerV(address Signer);
  event AddManOpV(uint256 ContractX, uint256 ManOpX, uint32 SigsRequired, uint32 SecsValid);
  event ChangeSignerV(address OldSignerA, address NewSignerA);
  event ConfirmSignerV(address SignerA);
  event UnConfirmSignerV(address SignerA);
  event ChangeContractV(uint256 ContractX, address OldContract, address NewContract);
  event UpdateManOpV(uint256 ManOpK, uint32 SigsRequired, uint32 SecsValid);
  event ManOpApprovedV(uint256 ManOpK, uint256 Id);
  event ApprovedManOpExecutedV(uint256 ManOpK);
  event PauseContractV(uint256 ContractX);
  event ResumeContractV(uint256 ContractX);
  event PauseManOpV(uint256 ManOpK);
  event ResumeManOpV(uint256 ManOpK);

  // No Constructor (Only the Owned one)
  // ==============

  // Initialisation/Setup Functions
  // ==============================

  // Owners: Deployer OpMan (self) Hub Admin

  // The OwnedOpMan constructor sets Deployer and OpMan (self)
  // Others must first be set by deploy script calls:
  //   OpMan.SetOwnerIMO(HUB_OWNER_X, Hub contract)
  //   OpMan.SetOwnerIMO(ADMIN_OWNER_X, PCL hw wallet account address as Admin)

  // Initialise()
  // ------------
  // To be called by deploy script to:
  // 1. Add initial contracts, signers, and manOps
  // Can only be called once.
  //
  // Arguments:
  // - vContractsYA  Array of contract addresses for Hub, Sale, Token, List, Mfund, Pfund, Poll in that order. Note, NOT OpMan which the fn uses this for.
  // - vSignersYA    Array of the addresses of the initial signers. These will need to be confirmed before they can be used for granting approvals.
  function Initialise(address[] vContractsYA, address[] vSignersYA) external IsInitialising {
    // Add initial contracts
    pAddContract(OPMAN_CONTRACT_X, address(this), true); // Self
    uint256 cX = 1;
    for (uint256 j=0; j<vContractsYA.length; j++) {
      pAddContract(cX, vContractsYA[j], cX != LIST_CONTRACT_X); // List is the only contract which isn't pausable
      cX++;
    }
    // Add initial signers
    for (j=0; j<vSignersYA.length; j++)
      pAddSigner(vSignersYA[j]);
    // Add initial (OpMan) manOps
    // pAddManOp(uint256 contractX, uint32 vSigsRequired, uint32 vSecsValid) private
    pAddManOp(OPMAN_CONTRACT_X, RESUME_CONTRACT_MO_X,           3, MIN); //  0 OpMan.ResumeContractMO()
    pAddManOp(OPMAN_CONTRACT_X, OPMAN_ADD_SIGNER_MO_X,          3, MIN); //  2 OpMan.AddSignerMO()
    pAddManOp(OPMAN_CONTRACT_X, OPMAN_CHANGE_SIGNER_MO_X,       3, MIN); //  4 OpMan.ChangeSignerMO()
    pAddManOp(OPMAN_CONTRACT_X, OPMAN_UPDATE_MAN_OP_MO_X,       3, MIN); //  5 OpMan.UpdateManOpMO()
    pAddManOp(HUB_CONTRACT_X,   HUB_SET_PCL_ACCOUNT_MO_X,       3, MIN); //  1 Hub.SetPclAccountMO()
    pAddManOp(HUB_CONTRACT_X,   HUB_START_SALE_MO_X,            3, MIN); //  2 Hub.StartSaleMO();
    pAddManOp(HUB_CONTRACT_X,   HUB_SOFT_CAP_REACHED_MO_X,      3, MIN); //  3 Hub.SoftCapReachedMO()
    pAddManOp(HUB_CONTRACT_X,   HUB_CLOSE_SALE_MO_X,            3, MIN); //  4 Hub.CloseSaleMO()
    pAddManOp(HUB_CONTRACT_X,   HUB_SET_LIST_ENTRY_BITS_MO_X,   3, MIN); //  5 Hub.SetListEntryBitsMO()
    pAddManOp(HUB_CONTRACT_X,   HUB_SET_TRAN_TO_PB_STATE_MO_X,  3, MIN); //  6 Hub.SetTransferToPacioBcStateMO()
    pAddManOp(HUB_CONTRACT_X,   HUB_NEW_OPMAN_CONTRACT_MO_X,    3, MIN); //  7 Hub.NewOpManContractMO()
    pAddManOp(HUB_CONTRACT_X,   HUB_NEW_HUB_CONTRACT_MO_X,      3, MIN); //  8 Hub.NewHubContractMO()
    pAddManOp(HUB_CONTRACT_X,   HUB_NEW_SALE_CONTRACT_MO_X,     3, MIN); //  9 Hub.NewSaleContractMO()
    pAddManOp(HUB_CONTRACT_X,   HUB_NEW_TOKEN_CONTRACT_MO_X,    3, MIN); // 10 Hub.NewTokenContractMO()
    pAddManOp(HUB_CONTRACT_X,   HUB_NEW_LIST_CONTRACT_MO_X,     3, MIN); // 11 Hub.NewListContractMO()
    pAddManOp(HUB_CONTRACT_X,   HUB_NEW_MFUND_CONTRACT_MO_X,    3, MIN); // 12 Hub.NewMfundContractMO()
    pAddManOp(HUB_CONTRACT_X,   HUB_NEW_PFUND_CONTRACT_MO_X,    3, MIN); // 13 Hub.NewPfundContractMO()
    pAddManOp(HUB_CONTRACT_X,   HUB_NEW_POLL_CONTRACT_MO_X,     3, MIN); // 14 Hub.NewPollContractMO()
    pAddManOp(HUB_CONTRACT_X,   HUB_NEW_ADMIN_ACCOUNT_MO_X,     3, MIN); // 15 Hub.NewAdminAccountMO()
    pAddManOp(HUB_CONTRACT_X,   HUB_NEW_WEB_ACCOUNT_MO_X,       3, MIN); // 16 Hub.NewWebAccountMO()
    pAddManOp(SALE_CONTRACT_X,  SALE_SET_CAPS_TRANCHES_MO_X,    3, MIN); //  1 Sale.SetCapsAndTranchesMO()
    pAddManOp(TOKEN_CONTRACT_X, TOKEN_TRAN_UNISSUED_TO_PB_MO_X, 3, MIN); //  1 Token.TransferUnIssuedPIOsToPacioBcMO()
    pAddManOp(MFUND_CONTRACT_X, MFUND_WITHDRAW_TAP_MO_X,        3, MIN); //  1 Mfund.WithdrawTapMO()
    pAddManOp(POLL_CONTRACT_X,  POLL_CLOSE_YES_MO_X,            3, MIN); //  1 Poll.ClosePollYesMO()
    pAddManOp(POLL_CONTRACT_X,  POLL_CLOSE_NO_MO_X,             3, MIN); //  2 Poll.ClosePollNoMO()
    iInitialisingB = false;
    emit InitialiseV(msg.sender);
  }

  // View Methods
  // ============
  function NumContracts() external view returns (uint256) {
    return pContractsYR.length;
  }
  function ContractXA(uint256 cX) external view returns (address) {
    require(cX < pContractsYR.length);
    return pContractsYR[cX].contractA;
  }
  function ContractX(uint256 cX) external view returns (address contractA, bool pausableB, bool pausedB, uint32 addedT, uint32 updatedT, uint32 numManOps, uint32[] manOpsY) {
    require(cX < pContractsYR.length);
    R_Contract storage srContractR = pContractsYR[cX];
    uint32[] memory manOpsYI = new uint32[](srContractR.numManOps);
    uint32 k;
    for (uint256 j=0; j<pManOpKsYU.length; j++) {
      uint256 manOpK = pManOpKsYU[j]; // pManOpKsYU is the array of the manOps mapping keys manOpK = cX * 100 + manOpX
      if (manOpK/100 == cX)
        manOpsYI[k++] = uint32(manOpK);
    }
    return (srContractR.contractA, srContractR.pausableB, srContractR.pausedB, srContractR.addedT, srContractR.updatedT, srContractR.numManOps, manOpsYI);
  }
  function MinNumSigners() external pure returns (uint32) {
    return MIN_NUM_SIGNERS;
  }
  function NumSigners() external view returns (uint256) {
    return pSignersYA.length;
  }
  function Signers() external view returns (address[]) {
    return pSignersYA;
  }
  function NumManagedOperations() external view returns (uint256) {
    return pManOpKsYU.length;
  }
  function ManagedOperationK(uint256 manOpK) external view returns (uint32 contractX, uint32 sigsRequired, uint32 secsValid, uint32 approvedT, uint256 approvals, bool pausedB) {
    R_ManOp storage srManOpR = pManOpsOpkMR[manOpK];
    require(srManOpR.sigsRequired > 0, 'ManOp not defined');
    return (srManOpR.contractX, srManOpR.sigsRequired, srManOpR.secsValid, srManOpR.approvedT, srManOpR.approvals, srManOpR.pausedB);
  }
  function SignerX(uint256 iX) external view returns (uint32 addedT, uint32 confirmedT, uint32 numSigs, uint32 lastSigT) {
    require(iX < pSignersYA.length);
    R_Signer storage srSignerR = pSignersAddrMR[pSignersYA[iX]];
    return (srSignerR.addedT, srSignerR.confirmedT, srSignerR.numSigs, srSignerR.lastSigT);
  }

  // Modifier functions
  // ==================
  modifier IsNotDuplicateContract(address contractA) {
  //require(pContractsAddrMX[contractA] == 0,'Duplicate contract'); Can't use this because OpMan has a cX of 0
    for (uint256 j=0; j<pContractsYR.length; j++)
      require(contractA != pContractsYR[j].contractA, 'Duplicate contract');
    _;
  }
  modifier IsNotDuplicateSigner(address vSignerA) {
    require(pSignersAddrMR[vSignerA].addedT == 0, 'Duplicate signer');
    _;
  }
  modifier IsConfirmedSigner {
    require(pIsConfirmedSignerB(), 'Not called by a confirmed signer');
    _;
  }
  modifier IsHubContractCallerOrConfirmedSigner {
    require(iIsHubContractCallerB() || pIsConfirmedSignerB(), 'Not called by Hub or a confirmed signer');
    _;
  }

  // Local private functions
  // =======================
  // OpMan.pAddContract()
  // --------------------
  // Called from Initialise() as part of processes:
  // 1. Add contracts, signers, and manOps via the Initialise() method to be called from the deploy script
  function pAddContract(uint256 contractX, address contractA, bool vPausableB) private IsNotDuplicateContract(contractA) {
    require(pContractsYR.length == contractX, 'AddContract call out of order');
    pContractsYR.push(R_Contract(
      contractA,   // address contractA;  // *
      vPausableB,  // bool    pausableB;  // * true if contract is pausable i.e. that the contract has a SetPause(bool B) function
      false,       // bool    pausedB;    // * true if contract is paused
      uint32(now), // uint32  addedT;     //
      0,           // uint32  updatedT;   // *
      0));         // uint32  numManOps;  // * number of manOps
                   // mapping (uint32
                   // => bool) manOpsOpxMB;// * To confirm ownership of ops by contract
                                           // |- * = can be updated via a managed op
    pContractsAddrMX[contractA] = contractX; // Mapping of contracts by address -> cX (contract index in pContractsYR)
    emit AddContractV(contractX, contractA, vPausableB);
  }

  // OpMan.pAddSigner()
  // ------------------
  // Called for processes:
  // 1. Add contracts, signers, and manOps via the Initialise() method to be called from the deploy script
  // 2. Admin to add additional signer as a managed op  AddSignertMO()
  // The IsNotDuplicateSigner() modifier call ensures that signers are unique.
  function pAddSigner(address vSignerA) private IsNotDuplicateSigner(vSignerA) {
    pSignersAddrMR[vSignerA] = R_Signer(
      uint32(now),  // uint32  addedT;
      0,            // uint32  confirmedT;
      0,            // uint32  numSigs;
      0);           // uint32  lastSigT;
    pSignersYA.push(vSignerA);
    emit AddSignerV(vSignerA);
  }

  // OpMan.pAddManOp()
  // -----------------
  // Called from Initialise() as part of processes:
  // 1. Add contracts, signers, and manOps via the Initialise() method to be called from the deploy script
  function pAddManOp(uint256 contractX, uint256 vManOpX, uint32 vSigsRequired, uint32 vSecsValid) private {
    require(contractX < pContractsYR.length,           'Unknown contract');
    require(pContractsYR[contractX].manOpsOpxMB[vManOpX] == false, 'ManOp already defined for contract');
    require(vSigsRequired >= MIN_NUM_SIGNERS, 'Insufficient required sigs');
    uint256 manOpK = contractX * 100 + vManOpX;
    pManOpsOpkMR[manOpK] = R_ManOp(
      uint32(contractX), // uint32 contractX;   // index of the contract with the operation to be approved
      vSigsRequired, // uint32 sigsRequired;
      vSecsValid,    // uint32 secsValid;
      0,             // uint32 approvedT;
      0,             // uint32 approvals;   // number of times the manOp has been approved or used
      false,         // bool   approvedB
      false);        // bool   pausedB;     // true if manOP is paused
    pManOpKsYU.push(manOpK);
    pContractsYR[contractX].numManOps++;
    pContractsYR[contractX].manOpsOpxMB[vManOpX] = true;
    emit AddManOpV(contractX, vManOpX, vSigsRequired, vSecsValid);
  }

  // OpMan.pIsConfirmedSignerB()
  // ---------------------------
  function pIsConfirmedSignerB() private view returns (bool) {
    return pSignersAddrMR[msg.sender].confirmedT > 0 && !iIsContractCallerB();
  }

  // OpMan.pIsManOpApproved()
  // ------------------------
  // Called from IsManOpApproved() and OpMan *MO() functions to check if approval for the manOp has been given by the required number of signers
  function pIsManOpApproved(uint256 manOpK) private returns (bool) {
    R_ManOp storage srManOpR = pManOpsOpkMR[manOpK];
    require(srManOpR.approvedB                                     // approved but approval not yet used
         && uint32(now) - srManOpR.approvedT <= srManOpR.secsValid // within time
         && !pContractsYR[srManOpR.contractX].pausedB              // contract is active
         && !srManOpR.pausedB,                                     // manOp is active
            'ManOp not approved'); // also serves to confirm that the op is defined
    emit ApprovedManOpExecutedV(manOpK);
    srManOpR.approvedB = false;
    srManOpR.approvals++;
    return true;
  }

  // State changing external methods
  // ===============================

  // OpMan.AddSignerMO()
  // -------------------
  // 2. Admin to add additional signer as a managed op
  // Called manually by Admin to add an additional signer not included in the initial deployment. Must be approved.
  function AddSignerMO(address vSignerA) external IsAdminCaller IsActive returns (bool) {
    require(pIsManOpApproved(OPMAN_ADD_SIGNER_MO_X)); // Same as OPMAN_CONTRACT_X * 100 + OPMAN_ADD_SIGNER_MO_X
    pAddSigner(vSignerA); // included IsNotDuplicateSigner() call
    return true;
  }

  // OpMan.ChangeSignerMO()
  // ----------------------
  // 3. Admin to change one signer to another as a managed op
  function ChangeSignerMO(address vOldSignerA, address vNewSignerA) external IsAdminCaller IsActive returns (bool) {
    require(pIsManOpApproved(OPMAN_CHANGE_SIGNER_MO_X)); // Same as OPMAN_CONTRACT_X * 100 + OPMAN_CHANGE_SIGNER_MO_X
    uint256 iX = pSignersYA.length;
    for (uint256 j=0; j<pSignersYA.length; j++) {
      if (pSignersYA[j] == vOldSignerA)
        iX = j;
    }
    require(iX < pSignersYA.length, 'Old signer not known');
    delete pSignersAddrMR[vOldSignerA];
    pSignersAddrMR[vNewSignerA] = R_Signer(
      uint32(now),  // uint32  addedT;
      0,            // uint32  confirmedT;
      0,            // uint32  numSigs;
      0);           // uint32  lastSigT;
    pSignersYA[iX] = vNewSignerA;
    emit ChangeSignerV(vOldSignerA, vNewSignerA);
    return true;
  }

  // OpMan.ConfirmSelfAsSigner()
  // ---------------------------
  // 4.1 Signer to confirm self as a signer
  function ConfirmSelfAsSigner() external IsActive returns (bool) {
    R_Signer storage srSignerR = pSignersAddrMR[msg.sender];
    require(srSignerR.addedT > 0, 'Not called by a signer');
    require(srSignerR.confirmedT == 0, 'Already confirmed');
    srSignerR.confirmedT = uint32(now);
    emit ConfirmSignerV(msg.sender);
    return true;
  }

  // OpMan.UnConfirmSigner()
  // -----------------------
  // 4.2 Admin to unconfirm (pause) a signer
  function UnConfirmSigner(address vSignerA) external IsAdminCaller returns (bool) {
    R_Signer storage srSignerR = pSignersAddrMR[vSignerA];
    require(srSignerR.confirmedT > 0, 'Signer not confirmed');
    srSignerR.confirmedT = 0;
    emit UnConfirmSignerV(vSignerA);
    return true;
  }

  // OpMan.UpdateManOpMO()
  // ---------------------
  // 5. Admin to update a manOp as a managed op
  // Can update sigsRequired and secsValid not contractX
  // Accessed by its Key
  function UpdateManOpMO(uint256 manOpK, uint32 vSigsRequired, uint32 vSecsValid) external IsAdminCaller IsActive returns (bool) {
    require(pIsManOpApproved(OPMAN_UPDATE_MAN_OP_MO_X)); // Same as OPMAN_CONTRACT_X * 100 + OPMAN_UPDATE_MAN_OP_MO_X
    R_ManOp storage srManOpR = pManOpsOpkMR[manOpK];
    require(srManOpR.sigsRequired > 0, 'ManOp not known');
    srManOpR.sigsRequired = vSigsRequired; // uint32 sigsRequired;
    srManOpR.secsValid    = vSecsValid;    // uint32 secsValid;
    emit UpdateManOpV(manOpK, vSigsRequired, vSecsValid);
    return true;
  }

  // OpMan.ApproveManOp()
  // --------------------
  // 6. Offline signatures to be submitted to approve a manOp  // Accessed by its Key
  // Version with v, r, s being passed as bytes[] sigs to pass multiple messages for splitting into v, r, s here required: pragma experimental ABIEncoderV2; Code kept in \Pacio\Development\ICO Dapps\DAICO\Pacio\OpMan\OpMan with bytes[] sigs.sol
  function ApproveManOp(uint256 manOpK, uint8[] sigV, bytes32[] sigR, bytes32[] sigS) external IsConfirmedSigner IsActive returns (bool) {
    R_ManOp storage srManOpR = pManOpsOpkMR[manOpK];
    require(srManOpR.sigsRequired > 0, 'ManOp not known');
    require(!srManOpR.pausedB,         'ManOp is paused');
    require(pContractsYR[srManOpR.contractX].manOpsOpxMB[manOpK%100], 'Contract ManOp Unknown'); // Gave a stock overflow on the manOpK%100
    require(srManOpR.sigsRequired <= sigR.length, 'Insufficient signatures');
    require(sigR.length == sigS.length && sigR.length == sigV.length);
    bytes32 hash = pPrefixed(keccak256(abi.encodePacked(manOpK, pNOnce)));
    uint32 nowUint32 = uint32(now);
    for (uint256 j = 0; j < sigR.length; j++) {
      R_Signer storage srSignerR = pSignersAddrMR[ecrecover(hash, sigV[j], sigR[j], sigS[j])];
      // Check that is a confirmed signer
      require(srSignerR.confirmedT > 0,       'Msg not signed by confirmed signer');
      require(srSignerR.lastSigT < nowUint32, 'Duplicate signer');
      srSignerR.lastSigT = nowUint32;
      srSignerR.numSigs++;
    }
    srManOpR.approvedT = nowUint32;
    srManOpR.approvedB = true;
    emit ManOpApprovedV(manOpK, pNOnce);
    pNOnce++;
    return true;
  }

  // Builds a prefixed hash to mimic the behaviour of eth_sign.
  function pPrefixed(bytes32 hash) private pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }

  // OpMan.IsManOpApproved()
  // -----------------------
  // Called from a contract function using operation management to check if approval for the manOp has been given
  // Process: 7. Approve or reject a request by a contract function to perform a managed op
  function IsManOpApproved(uint256 vManOpX) external IsContractCaller IsActive returns (bool) {
    uint256 cX = pContractsAddrMX[msg.sender];
    require(cX > 0 || msg.sender == address(this), 'Not called from known contract'); // The '|| msg.sender == address(this)' test is because cX == 0 (OPMAN_CONTRACT_X) for OpMan itself.
    return pIsManOpApproved(cX * 100 + vManOpX);  // key = cX * 100 + manOpX
  }

  // OpMan.PauseContract()
  // ---------------------
  // 8.1 Hub call or Signer to pause a contract, with a call to the contract's Pause() fn if the contract has one. Not a managed op.
  function PauseContract(uint256 contractX) external IsHubContractCallerOrConfirmedSigner returns (bool) {
    require(contractX < pContractsYR.length, 'Contract not known');
    R_Contract storage srContractR = pContractsYR[contractX];
    srContractR.pausedB = true;
    if (srContractR.pausableB)
      I_Owned(srContractR.contractA).Pause();
    emit PauseContractV(contractX);
    return true;
  }

  // OpMan.PauseManOp()
  // ------------------
  // 8.2 Signer to pause a manOp. Not a managed op.
  // Accessed by its Key
  function PauseManOp(uint256 manOpK) external IsConfirmedSigner returns (bool) {
    R_ManOp storage srManOpR = pManOpsOpkMR[manOpK];
    require(srManOpR.sigsRequired > 0, 'ManOp not known'); // op is defined
    require(!srManOpR.pausedB,         'ManOp is paused');
    srManOpR.pausedB = true;
    emit PauseManOpV(manOpK);
    return true;
  }

  // OpMan.ResumeContractMO()
  // ------------------------
  // 9.1 Signer to resume a contract as a managed op with a call to the contract's ResumeMO() fn if the contract has one
  function ResumeContractMO(uint256 contractX) external IsConfirmedSigner IsActive returns (bool) {
    require(contractX < pContractsYR.length, 'Contract not known');
    require(pIsManOpApproved(contractX * 100)); // No need for + RESUME_CONTRACT_MO_X as RESUME_CONTRACT_MO_X is 0
    R_Contract storage srContractR = pContractsYR[contractX];
    srContractR.pausedB = false;
    if (srContractR.pausableB)
      I_Owned(srContractR.contractA).ResumeMO();
    emit ResumeContractV(contractX);
    return true;
  }

  // OpMan.ResumeManOpMO()
  // ---------------------
  // 9.2 Signer to resume a manOp as a managed op
  function ResumeManOpMO(uint256 manOpK) external IsConfirmedSigner IsActive returns (bool) {
    R_ManOp storage srManOpR = pManOpsOpkMR[manOpK];
    require(srManOpR.sigsRequired > 0, 'ManOp not known'); // op is defined
    require(srManOpR.pausedB,         'ManOp not paused');
    require(pIsManOpApproved(manOpK));
    srManOpR.pausedB = false;
    emit ResumeManOpV(manOpK);
    return true;
  }

  // OpMan.ChangeContract()
  // ----------------------
  // Called from Hub.New*Contract() functions.
  // New contract address must be unique
  function ChangeContract(uint256 contractX, address newContractA) external IsHubContractCaller IsNotDuplicateContract(newContractA) IsActive returns (bool) {
    require(contractX < pContractsYR.length, 'Contract not known');
    R_Contract storage srContractR = pContractsYR[contractX];
    require(srContractR.addedT > 0, 'Contract not known'); // contract must exist
    emit ChangeContractV(contractX, srContractR.contractA, newContractA);
    delete pContractsAddrMX[srContractR.contractA]; // /- Mapping of contracts by address -> cX (contract index in pContractsYR)
    pContractsAddrMX[newContractA] = contractX;     // |
    srContractR.contractA = newContractA;
    srContractR.updatedT = uint32(now);
    // Owners: Deployer OpMan (self) Hub Admin
    if (contractX == HUB_CONTRACT_X)
      iOwnersYA[HUB_OWNER_X] = newContractA;
    return true;
  }

  // OpMan.NewOwner()
  // ---------------
  // Called from Hub.NewAdminAccountMO()  with ownerX = ADMIN_OWNER_X if the Admin account is changed
  function NewOwner(uint256 ownerX, address newOwnerA) external IsHubContractCaller {
    emit ChangeOwnerV(iOwnersYA[ownerX], newOwnerA, ownerX);
    iOwnersYA[ownerX] = newOwnerA;
  }

} // End OpMan contract

