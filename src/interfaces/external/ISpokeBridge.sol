// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title ISpokeBridge
 * @notice Interface for the SpokeBridge contract
 */
interface ISpokeBridge {
  /**
   * @notice Increase the lock position
   * @param _additionalAmountToLock The additional amount to lock
   * @param _expiry The expiry
   * @param _gasLimit The gas limit
   */
  function increaseLockPosition(uint128 _additionalAmountToLock, uint128 _expiry, uint256 _gasLimit) external;

  /**
   * @notice Get the Gateway contract address
   * @return _gateway The Gateway contract address
   */
  function gateway() external view returns (address _gateway);

  /**
   * @notice Get the EVERCLEAR_ID
   * @return _everclearId The EVERCLEAR_ID
   */
  function EVERCLEAR_ID() external view returns (uint32 _everclearId);
}
