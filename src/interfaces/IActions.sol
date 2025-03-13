// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

interface IActions {
  struct Action {
    address target;
    bytes data;
    uint256 value;
  }

  function getActions() external returns (Action[] memory);
}
