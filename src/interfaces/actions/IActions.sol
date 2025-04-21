// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

interface IActions {
  struct Action {
    address target;
    bytes data;
    uint256 value;
  }

  function getActions() external returns (Action[] memory);
}
