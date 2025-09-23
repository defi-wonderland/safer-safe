// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IEverclearTokenConversionFactory
 * @notice Interface for the EverclearTokenConversionFactory contract
 */
interface IEverclearTokenConversionFactory {
  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates an EverclearTokenConversion contract
   * @param _lockbox The xERC20Lockbox contract address
   * @param _next The NEXT contract address
   * @return _everclearTokenConversion The EverclearTokenConversion contract address
   */
  function createEverclearTokenConversion(
    address _lockbox,
    address _next
  ) external returns (address _everclearTokenConversion);
}
