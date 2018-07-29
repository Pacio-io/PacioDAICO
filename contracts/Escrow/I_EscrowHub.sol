/* \Escrow\I_EscrowHub.sol started 2018.07.11

Interface for the Escrow contract external functions which are called from the Hub contract.

*/

pragma solidity ^0.4.24;

interface I_EscrowHub {
  function WeiInEscrow() external view returns (uint256);
  function SetPclAccount(address vPclAccountA) external;
  function StartSale() external;
  function SoftCapReached() external;
  function EndSale() external;
}
// End I_EscrowHub interface
