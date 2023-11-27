// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
/**
 * @title StakePool
 * @notice Represents a contract where a token owner has put her tokens up for others to stake and earn said tokens.
 */
contract TestToken is ERC20 {

  constructor(
  ) ERC20("Test Token", "$TEST") {
      _mint(msg.sender, (10 ** 10) * (10 ** 18));
  } 
}