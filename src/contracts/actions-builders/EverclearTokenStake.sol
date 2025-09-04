// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ActionBuilder} from 'contracts/actions-builders/ActionBuilder.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';
import {IEverclearTokenStake} from 'interfaces/actions-builders/IEverclearTokenStake.sol';
import {IGateway} from 'interfaces/external/IGateway.sol';
import {ISpokeBridge} from 'interfaces/external/ISpokeBridge.sol';
import {IVestingEscrow} from 'interfaces/external/IVestingEscrow.sol';
import {IVestingWallet} from 'interfaces/external/IVestingWallet.sol';
import {IxERC20Lockbox} from 'interfaces/external/IxERC20Lockbox.sol';

/**
 * @title EverclearTokenStake
 * @notice Contract that increases the stake of CLEAR
 */
contract EverclearTokenStake is IEverclearTokenStake, ActionBuilder {
  // ~~~ STORAGE ~~~

  /// @inheritdoc IEverclearTokenStake
  IVestingEscrow public immutable VESTING_ESCROW;

  /// @inheritdoc IEverclearTokenStake
  IVestingWallet public immutable VESTING_WALLET;

  /// @inheritdoc IEverclearTokenStake
  ISpokeBridge public immutable SPOKE_BRIDGE;

  /// @inheritdoc IEverclearTokenStake
  IxERC20Lockbox public immutable CLEAR_LOCKBOX;

  /// @inheritdoc IEverclearTokenStake
  IERC20 public immutable NEXT;

  /// @inheritdoc IEverclearTokenStake
  IERC20 public immutable CLEAR;

  /// @inheritdoc IEverclearTokenStake
  address public immutable SAFE;

  /// @inheritdoc IEverclearTokenStake
  uint256 public immutable LOCK_TIME;

  // ~~~ CONSTRUCTOR ~~~

  /**
   * @notice Constructor that sets up the variables
   * @param _parent The parent that deployed the action builder
   * @param _vestingEscrow The vesting escrow contract address
   * @param _vestingWallet The vesting wallet contract address
   * @param _spokeBridge The spoke bridge contract address
   * @param _clearLockbox The clear lockbox contract address
   * @param _next The NEXT contract address
   * @param _clear The CLEAR contract address
   * @param _safe The SAFE contract address
   * @param _lockTime The lock time
   */
  constructor(
    address _parent,
    address _vestingEscrow,
    address _vestingWallet,
    address _spokeBridge,
    address _clearLockbox,
    address _next,
    address _clear,
    address _safe,
    uint256 _lockTime
  ) ActionBuilder(_parent) {
    VESTING_ESCROW = IVestingEscrow(_vestingEscrow);
    VESTING_WALLET = IVestingWallet(_vestingWallet);
    SPOKE_BRIDGE = ISpokeBridge(_spokeBridge);
    CLEAR_LOCKBOX = IxERC20Lockbox(_clearLockbox);
    NEXT = IERC20(_next);
    CLEAR = IERC20(_clear);
    SAFE = _safe;
    LOCK_TIME = _lockTime;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc ActionBuilder
  function getActions() external view override returns (Action[] memory _actions) {
    _actions = new Action[](6);

    // NOTE: since this is a view function and does not update state, we need to calculate
    // how much tokens are transferred when calling release() on step 2.

    // First get the unclaimed amount
    uint256 _unclaimed = VESTING_ESCROW.unclaimed();
    // Get current balance of NEXT
    uint256 _nextBalance = NEXT.balanceOf(address(VESTING_WALLET));
    // Get the releaseable amount at the time of enqueuing (same behaviour as releaseable() on VESTING_WALLET)
    uint256 _amountReleasable = VESTING_WALLET.vestedAmount(uint64(block.timestamp)) - VESTING_WALLET.released();
    uint256 _nextBalanceAfterRelease = _nextBalance + _unclaimed;
    uint256 _amountToBeReleased =
      _nextBalanceAfterRelease < _amountReleasable ? _nextBalanceAfterRelease : _amountReleasable;

    // 1) Claim
    _actions[0] = Action({
      target: address(VESTING_WALLET),
      data: abi.encodeCall(IVestingWallet.claim, (address(VESTING_ESCROW))),
      value: 0
    });

    // 2) Release
    _actions[1] = Action({target: address(VESTING_WALLET), data: abi.encodeCall(IVestingWallet.release, ()), value: 0});

    // 3) Approve
    _actions[2] = Action({
      target: address(NEXT),
      data: abi.encodeCall(IERC20.approve, (address(CLEAR_LOCKBOX), _amountToBeReleased)),
      value: 0
    });

    // 4) Deposit
    _actions[3] = Action({
      target: address(CLEAR_LOCKBOX),
      data: abi.encodeCall(IxERC20Lockbox.deposit, (_amountToBeReleased)),
      value: 0
    });

    // 5) Approve
    _actions[4] = Action({
      target: address(CLEAR),
      data: abi.encodeCall(IERC20.approve, (address(SPOKE_BRIDGE), _amountToBeReleased)),
      value: 0
    });

    // 6) Increase lock position

    uint256 _gasLimit = 500_000;

    // NOTE: expiry % 7 days must be 0
    uint128 _lockTime = uint128(block.timestamp + LOCK_TIME);
    _lockTime = (_lockTime / 1 weeks) * 1 weeks;

    // NOTE: get the fee from the gateway
    uint256 _value = IGateway(SPOKE_BRIDGE.gateway()).quoteMessage(
      SPOKE_BRIDGE.EVERCLEAR_ID(), abi.encode(2, SAFE, _amountToBeReleased, _lockTime), _gasLimit
    );

    _actions[5] = Action({
      target: address(SPOKE_BRIDGE),
      data: abi.encodeCall(ISpokeBridge.increaseLockPosition, (uint128(_amountToBeReleased), _lockTime, _gasLimit)),
      // NOTE: duplicate just in case the value changes while waiting for the transaction to be executed
      // Leftover fee is reimbursed by the gateway
      value: _value * 2
    });
  }
}
