// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';

import {IERC20} from 'forge-std/interfaces/IERC20.sol';
import {EverclearTokenStake} from 'src/contracts/actions-builders/EverclearTokenStake.sol';
import {IActionsBuilder} from 'src/interfaces/actions-builders/IActionsBuilder.sol';
import {IGateway} from 'src/interfaces/external/IGateway.sol';
import {ISpokeBridge} from 'src/interfaces/external/ISpokeBridge.sol';
import {IVestingEscrow} from 'src/interfaces/external/IVestingEscrow.sol';
import {IVestingWallet} from 'src/interfaces/external/IVestingWallet.sol';
import {IxERC20Lockbox} from 'src/interfaces/external/IxERC20Lockbox.sol';

contract UnitEverclearTokenStake is Test {
  uint256 public constant LOCK_TIME = 100;
  uint256 public constant GAS_LIMIT = 500_000;

  EverclearTokenStake public everclearTokenStake;
  address public vestingEscrow = makeAddr('vestingEscrow');
  address public vestingWallet = makeAddr('vestingWallet');
  address public spokeBridge = makeAddr('spokeBridge');
  address public clearLockbox = makeAddr('clearLockbox');
  address public next = makeAddr('NEXT');
  address public clear = makeAddr('CLEAR');
  address public safe = makeAddr('SAFE');
  address public gateway = makeAddr('gateway');

  function setUp() external {
    everclearTokenStake = new EverclearTokenStake(
      address(0), vestingEscrow, vestingWallet, spokeBridge, clearLockbox, next, clear, safe, LOCK_TIME
    );
  }

  function test_ConstructorWhenCalled() external view {
    // it sets the vesting escrow address
    assertEq(address(everclearTokenStake.VESTING_ESCROW()), vestingEscrow);
    // it sets the vesting wallet address
    assertEq(address(everclearTokenStake.VESTING_WALLET()), vestingWallet);
    // it sets the spoke bridge address
    assertEq(address(everclearTokenStake.SPOKE_BRIDGE()), spokeBridge);
    // it sets the clear lockbox address
    assertEq(address(everclearTokenStake.CLEAR_LOCKBOX()), clearLockbox);
    // it sets the NEXT address
    assertEq(address(everclearTokenStake.NEXT()), next);
    // it sets the CLEAR address
    assertEq(address(everclearTokenStake.CLEAR()), clear);
    // it sets the SAFE address
    assertEq(everclearTokenStake.SAFE(), safe);
    // it sets the lock time
    assertEq(everclearTokenStake.LOCK_TIME(), LOCK_TIME);
  }

  function test_GetActionsWhenCalled(
    uint256 _unclaimed,
    uint256 _nextBalance,
    uint256 _vestedAmount,
    uint256 _released,
    uint256 _messageFee,
    uint32 _everclearId
  ) external {
    vm.assume(_vestedAmount > _released);
    _messageFee = bound(_messageFee, 1, type(uint256).max / 2);
    _nextBalance = bound(_nextBalance, 1, type(uint256).max / 2);
    _unclaimed = bound(_unclaimed, 1, type(uint256).max / 2);

    // it calculates the amount to be released
    _mockAndExpect(vestingEscrow, abi.encodeWithSelector(IVestingEscrow.unclaimed.selector), abi.encode(_unclaimed));
    _mockAndExpect(next, abi.encodeWithSelector(IERC20.balanceOf.selector, vestingWallet), abi.encode(_nextBalance));
    _mockAndExpect(vestingWallet, abi.encodeWithSelector(IVestingWallet.released.selector), abi.encode(_released));
    _mockAndExpect(
      vestingWallet,
      abi.encodeWithSelector(IVestingWallet.vestedAmount.selector, uint64(block.timestamp)),
      abi.encode(_vestedAmount)
    );

    uint256 _amountReleasable = _vestedAmount - _released;
    uint256 _nextBalanceAfterRelease = _nextBalance + _unclaimed;
    uint256 _amountToBeReleased =
      _nextBalanceAfterRelease < _amountReleasable ? _nextBalanceAfterRelease : _amountReleasable;
    uint128 _lockTime = uint128(block.timestamp + LOCK_TIME);
    _lockTime = (_lockTime / 1 weeks) * 1 weeks;

    _mockAndExpect(spokeBridge, abi.encodeWithSelector(ISpokeBridge.gateway.selector), abi.encode(gateway));
    _mockAndExpect(spokeBridge, abi.encodeWithSelector(ISpokeBridge.EVERCLEAR_ID.selector), abi.encode(_everclearId));
    _mockAndExpect(
      gateway,
      abi.encodeWithSelector(
        IGateway.quoteMessage.selector, _everclearId, abi.encode(2, safe, _amountToBeReleased, _lockTime), GAS_LIMIT
      ),
      abi.encode(_messageFee)
    );
    // it returns an action to claim
    IActionsBuilder.Action[] memory actions = everclearTokenStake.getActions();
    assertEq(actions[0].target, address(vestingWallet));
    assertEq(actions[0].data, abi.encodeCall(IVestingWallet.claim, (address(vestingEscrow))));
    assertEq(actions[0].value, 0);

    // it returns an action to release
    assertEq(actions[1].target, address(vestingWallet));
    assertEq(actions[1].data, abi.encodeCall(IVestingWallet.release, ()));
    assertEq(actions[1].value, 0);

    // it returns an action to approve the NEXT amount to be released
    assertEq(actions[2].target, address(next));
    assertEq(actions[2].data, abi.encodeCall(IERC20.approve, (address(clearLockbox), _amountToBeReleased)));
    assertEq(actions[2].value, 0);

    // it returns an action to deposit the amount to be released
    assertEq(actions[3].target, address(clearLockbox));
    assertEq(actions[3].data, abi.encodeCall(IxERC20Lockbox.deposit, (_amountToBeReleased)));
    assertEq(actions[3].value, 0);

    // it returns an action to approve CLEAR the amount to be released
    assertEq(actions[4].target, address(clear));
    assertEq(actions[4].data, abi.encodeCall(IERC20.approve, (address(spokeBridge), _amountToBeReleased)));
    assertEq(actions[4].value, 0);

    // it returns an action to increase the lock position
    assertEq(actions[5].target, address(spokeBridge));
    assertEq(
      actions[5].data,
      abi.encodeCall(ISpokeBridge.increaseLockPosition, (uint128(_amountToBeReleased), _lockTime, GAS_LIMIT))
    );
    assertEq(actions[5].value, _messageFee * 2);
  }

  function _mockAndExpect(address _target, bytes memory _call, bytes memory _returnData) internal {
    vm.mockCall(_target, _call, _returnData);
    vm.expectCall(_target, _call);
  }
}
