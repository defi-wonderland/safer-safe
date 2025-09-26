// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IActionHubChild {
  /**
   * @notice Returns the hub address
   * @return _hub The hub address
   */
  function HUB() external view returns (address _hub);
}
