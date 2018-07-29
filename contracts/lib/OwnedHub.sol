// lib\OwnedHub.sol
//
// Version of Owned for Hub which is owned by Deployer, OpMan, Admin, Sale
// Is pausable

pragma solidity ^0.4.24;

import "./Constants.sol";
import "../OpMan/I_OpMan.sol";

contract OwnedHub is Constants {
  uint256 internal constant NUM_OWNERS = 4;
  bool    internal iInitialisingB = true; // Starts in the initialising state
  bool    internal iPausedB = true;       // Starts paused
  address[NUM_OWNERS] internal iOwnersYA; // 0 Deployer
                                          // 1 OpMan owner, in this OpMan case is self
                                          // 2 Admin owner
                                          // 3 Sale  owner
                                          // |- owner X
  // Constructor NOT payable
  // -----------
  constructor() internal {
    iOwnersYA = [msg.sender, msg.sender];  // only need up to 1 OpMan to be set here
  }

  // View Methods
  // ------------
  function Owners() external view returns (address[NUM_OWNERS]) {
    return iOwnersYA;
  }
  function Paused() external view returns (bool) {
    return iPausedB;
  }
  function Initialising() external view returns (bool) {
    return iInitialisingB;
  }

  // Modifier functions
  // ------------------
  modifier IsDeployerCaller {
    require(msg.sender == iOwnersYA[DEPLOYER_X], "Not required Deployer caller");
    _;
  }
  modifier IsOpManCaller {
    require(msg.sender == iOwnersYA[OP_MAN_OWNER_X], "Not required OpMan caller");
    _;
  }
  modifier IsAdminCaller {
    require(msg.sender == iOwnersYA[ADMIN_OWNER_X], "Not required Admin caller");
    _;
  }
  modifier IsSaleCaller {
    require(msg.sender == iOwnersYA[SALE_OWNER_X], "Not required Sale caller");
    _;
  }
  modifier IsSaleOrAdminCaller {
    require(msg.sender == iOwnersYA[SALE_OWNER_X] || msg.sender == iOwnersYA[ADMIN_OWNER_X], "Not required Sale or Admin caller");
    _;
  }
  modifier IsActive {
    require(!iPausedB, "Contract is Paused");
    _;
  }

  // Events
  // ------
  event ChangeOwnerV(address indexed PreviousOwner, address NewOwner, uint256 OwnerId);
  event PausedV();
  event ResumedV();

  // State changing external methods
  // -------------------------------
  // ChangeOwnerMO()
  // ---------------
  // Called by OpMan.ChangeContractOwnerMO(vContractX, vOwnerX) IsAdminCaller IsConfirmedSigner which is a managed op
  // Can be called during deployment when iInitialisingB is set and msg.sender is the same as that for the constructor call to set the owners, if OpMan is set last.
  function ChangeOwnerMO(uint256 vOwnerX, address vNewOwnerA) external IsOpManCaller {
  //require((iInitialisingB || I_OpMan(iOwnersYA[OP_MAN_OWNER_X]).IsManOpApproved(CHANGE_OWNER_BASE_X + vOwnerX))
    require((iInitialisingB || I_OpMan(iOwnersYA[OP_MAN_OWNER_X]).IsManOpApproved(vOwnerX))
         && vNewOwnerA != iOwnersYA[DEPLOYER_X]
         && vNewOwnerA != iOwnersYA[OP_MAN_OWNER_X]
         && vNewOwnerA != iOwnersYA[ADMIN_OWNER_X]
         && vNewOwnerA != iOwnersYA[SALE_OWNER_X]);
    emit ChangeOwnerV(iOwnersYA[vOwnerX], vNewOwnerA, vOwnerX);
    iOwnersYA[vOwnerX] = vNewOwnerA;
  }

  // Pause()
  // -------
  // Called by OpMan.Pause(vContractX) IsConfirmedSigner. Not a managed op.
  function Pause() external IsOpManCaller IsActive {
    iPausedB = true;
    emit PausedV();
  }

  // ResumeMO()
  // ----------
  // Called by OpMan.ResumeContractMO(vContractX) IsConfirmedSigner which is a managed op
  function ResumeMO() external IsOpManCaller {
    require(I_OpMan(iOwnersYA[OP_MAN_OWNER_X]).IsManOpApproved(RESUME_X));
    iPausedB = false;
    emit ResumedV();
  }
} // End OwnedHub contract
