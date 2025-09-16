// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from 'forge-std/interfaces/IERC20.sol';
import {IxERC20Lockbox} from 'interfaces/external/IxERC20Lockbox.sol';

/**
 * @title IEverclearTokenConversion
 * @notice Interface for an EverclearTokenConversion contract
 */
interface IEverclearTokenConversion {
  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Gets the xERC20Lockbox contract
   * @return _clearLockbox The xERC20Lockbox contract address
   */
  function CLEAR_LOCKBOX() external view returns (IxERC20Lockbox _clearLockbox);

  /**
   * @notice Gets the NEXT contract
   * @return _next The NEXT contract address
   */
  function NEXT() external view returns (IERC20 _next);

  /**
   * @notice Gets the SAFE contract
   * @return _safe The SAFE contract address
   */
  function SAFE() external view returns (address _safe);
}
