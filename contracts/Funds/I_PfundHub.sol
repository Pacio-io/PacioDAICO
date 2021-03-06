/* \Funds\I_PfundHub.sol started 2018.07.11

Interface for the Pfund contract external functions which are called from the Hub contract.

*/

pragma solidity ^0.4.24;

interface I_PfundHub {
  function Paused() external view returns (bool);
  function FundWei() external view returns (uint256);
  function SetPclAccount(address vPclAccountA) external;
  function StateChange(uint32 vState) external;
  function PMTransfer(address vSenderA, uint256 vWei, bool tranche1B) external;
  function Refund(uint256 vRefundId, address toA, uint256 vRefundWei, uint32 vRefundBit) external returns (bool);
  function NewOwner(uint256, address) external;
  function NewMfundContract(address) external;
}
// End I_PfundHub interface
