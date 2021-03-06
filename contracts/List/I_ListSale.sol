/* \List\I_ListSale.sol

Interface for the List contract external functions which are called from the Sale contract.

*/

pragma solidity ^0.4.24;

interface I_ListSale {
  function BonusPcAndBits(address accountA) external view returns (uint32 bonusCentiPc, uint32 bits);
  function PrepurchaseDeposit(address toA, uint256 vWei, uint32 tranche1Bit) external returns (bool);
}
// End I_ListSale interface
