// lib\OwnedList.sol
//
// Version of Owned for List which is owned by Deployer OpMan Hub Token Sale Poll
// Is NOT pausable

pragma solidity ^0.4.24;

import "./Constants.sol";
import "../OpMan/I_OpMan.sol";

contract OwnedList is Constants {
  uint256 internal constant NUM_OWNERS = 6;
  bool    internal iInitialisingB = true; // Starts in the initialising state
  address[NUM_OWNERS] internal iOwnersYA;

  // Constructor NOT payable
  // -----------
  constructor() internal {
    iOwnersYA[DEPLOYER_X] = msg.sender;  // only need Deployer to be set here
  }

  // View Methods
  // ------------
  function Owners() external view returns (address[NUM_OWNERS]) {
    return iOwnersYA;
  }
  function iIsInitialisingB() internal view returns (bool) {
    return iInitialisingB && msg.sender == iOwnersYA[DEPLOYER_X];
  }
  function pIsOpManContractCallerB() private view returns (bool) {
    return msg.sender == iOwnersYA[OP_MAN_OWNER_X] && pIsContractCallerB();
  }
  function pIsContractCallerB() private view returns (bool) {
    address callerA = msg.sender; // need this because compilation fails on the '.' for extcodesize(msg.sender)
    uint256 codeSize;
    assembly {codeSize := extcodesize(callerA)}
    return codeSize > 0;
  }

  // Modifier functions
  // ------------------
  modifier IsInitialising {
    require(iIsInitialisingB(), "Not initialising");
    _;
  }
  modifier IsOpManContractCaller {
    require(pIsOpManContractCallerB(), "Not required OpMan caller");
    _;
  }
  modifier IsHubContractCaller {
    require(msg.sender == iOwnersYA[HUB_OWNER_X] && pIsContractCallerB(), "Not required Hub caller");
    _;
  }
  modifier IsSaleContractCaller {
    require(msg.sender == iOwnersYA[SALE_OWNER_X] && pIsContractCallerB(), "Not required Sale caller");
    _;
  }
  modifier IsPollContractCaller {
    require(msg.sender == iOwnersYA[POLL_OWNER_X] && pIsContractCallerB(), "Not required Poll caller");
    _;
  }
  modifier IsTokenContractCaller {
    require(msg.sender == iOwnersYA[TOKEN_OWNER_X] && pIsContractCallerB(), "Not required Token caller");
    _;
  }

  // Events
  // ------
  event ChangeOwnerV(address indexed PreviousOwner, address NewOwner, uint256 OwnerId);

  // State changing external methods
  // -------------------------------
  // ChangeOwnerMO()
  // ---------------
  // Called by OpMan.ChangeContractOwnerMO(vContractX, vOwnerX) IsAdminCaller IsConfirmedSigner which is a managed op
  // Can be called directly during deployment when initialising
  function ChangeOwnerMO(uint256 vOwnerX, address vNewOwnerA) external {
    require(iIsInitialisingB() || (pIsOpManContractCallerB() && I_OpMan(iOwnersYA[OP_MAN_OWNER_X]).IsManOpApproved(vOwnerX)));
    for (uint256 j=0; j<NUM_OWNERS; j++)
      require(vNewOwnerA != iOwnersYA[j], 'Duplicate owner');
    emit ChangeOwnerV(iOwnersYA[vOwnerX], vNewOwnerA, vOwnerX);
    iOwnersYA[vOwnerX] = vNewOwnerA;
  }

} // End OwnedList contract
