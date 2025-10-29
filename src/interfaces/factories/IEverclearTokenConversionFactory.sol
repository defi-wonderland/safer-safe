// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IFactory} from 'interfaces/factories/IFactory.sol';

/**
 * @title IEverclearTokenConversionFactory
 * @notice Interface for the EverclearTokenConversionFactory contract
 */
interface IEverclearTokenConversionFactory is IFactory {
  // ~~~ EVENTS ~~~

  /**
   * @notice Emitted when a new EverclearTokenConversion contract is created
   * @param _everclearTokenConversion The address of the created EverclearTokenConversion contract
   * @param _lockbox The xERC20Lockbox contract address
   * @param _next The NEXT contract address
   */
  event EverclearTokenConversionCreated(
    address indexed _everclearTokenConversion, address indexed _lockbox, address indexed _next
  );

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
