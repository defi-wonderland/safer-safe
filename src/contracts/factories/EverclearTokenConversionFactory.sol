// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {EverclearTokenConversion} from 'contracts/actions-builders/EverclearTokenConversion.sol';
import {Factory} from 'contracts/factories/Factory.sol';
import {IEverclearTokenConversionFactory} from 'interfaces/factories/IEverclearTokenConversionFactory.sol';

/**
 * @title EverclearTokenConversionFactory
 * @notice Contract that deploys EverclearTokenConversion contracts
 */
contract EverclearTokenConversionFactory is IEverclearTokenConversionFactory, Factory {
  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc IEverclearTokenConversionFactory
  function createEverclearTokenConversion(
    address _lockbox,
    address _next,
    address _safe
  ) external returns (address _everclearTokenConversion) {
    _everclearTokenConversion = address(new EverclearTokenConversion(address(this), _lockbox, _next, _safe));

    _children[_everclearTokenConversion] = true;
  }
}
