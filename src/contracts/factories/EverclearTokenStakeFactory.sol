// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {EverclearTokenStake} from 'contracts/actions-builders/EverclearTokenStake.sol';
import {Factory} from 'contracts/factories/Factory.sol';
import {IEverclearTokenStakeFactory} from 'interfaces/factories/IEverclearTokenStakeFactory.sol';

/**
 * @title EverclearTokenStakeFactory
 * @notice Contract that deploys EverclearTokenStake contracts
 */
contract EverclearTokenStakeFactory is IEverclearTokenStakeFactory, Factory {
  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc IEverclearTokenStakeFactory
  function createEverclearTokenStake(
    address _vestingEscrow,
    address _vestingWallet,
    address _spokeBridge,
    address _clearLockbox,
    address _next,
    address _clear,
    address _safe,
    uint256 _lockTime
  ) external returns (address _everclearTokenStake) {
    _everclearTokenStake = address(
      new EverclearTokenStake(
        _vestingEscrow, _vestingWallet, _spokeBridge, _clearLockbox, _next, _clear, _safe, _lockTime
      )
    );

    _children[_everclearTokenStake] = true;
  }
}
