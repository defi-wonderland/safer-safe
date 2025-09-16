// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from 'forge-std/interfaces/IERC20.sol';
import {ISpokeBridge} from 'interfaces/external/ISpokeBridge.sol';
import {IVestingEscrow} from 'interfaces/external/IVestingEscrow.sol';
import {IVestingWallet} from 'interfaces/external/IVestingWallet.sol';
import {IxERC20Lockbox} from 'interfaces/external/IxERC20Lockbox.sol';

/**
 * @title IEverclearTokenStake
 * @notice Interface for the EverclearTokenStake contract
 */
interface IEverclearTokenStake {
  /**
   * @notice Get the VestingEscrow contract address
   * @return _vestingEscrow The VestingEscrow contract address
   */
  function VESTING_ESCROW() external view returns (IVestingEscrow _vestingEscrow);

  /**
   * @notice Get the VestingWallet contract address
   * @return _vestingWallet The VestingWallet contract address
   */
  function VESTING_WALLET() external view returns (IVestingWallet _vestingWallet);

  /**
   * @notice Get the SpokeBridge contract address
   * @return _spokeBridge The SpokeBridge contract address
   */
  function SPOKE_BRIDGE() external view returns (ISpokeBridge _spokeBridge);

  /**
   * @notice Get the xERC20Lockbox contract address
   * @return _clearLockbox The xERC20Lockbox contract address
   */
  function CLEAR_LOCKBOX() external view returns (IxERC20Lockbox _clearLockbox);

  /**
   * @notice Get the NEXT contract address
   * @return _next The NEXT contract address
   */
  function NEXT() external view returns (IERC20 _next);

  /**
   * @notice Get the CLEAR contract address
   * @return _clear The CLEAR contract address
   */
  function CLEAR() external view returns (IERC20 _clear);

  /**
   * @notice Get the SAFE contract address
   * @return _safe The SAFE contract address
   */
  function SAFE() external view returns (address _safe);

  /**
   * @notice Get the LOCK_TIME
   * @return _lockTime The LOCK_TIME
   */
  function LOCK_TIME() external view returns (uint256 _lockTime);
}
