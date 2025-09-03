// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {IOwnerManager} from '@safe-smart-account/interfaces/IOwnerManager.sol';
import {Test} from 'forge-std/Test.sol';
import {CappedTokenTransfersHub} from 'src/contracts/action-hubs/CappedTokenTransfersHub.sol';
import {ISafeManageable} from 'src/interfaces/ISafeManageable.sol';

import {ICappedTokenTransfersHub} from 'src/interfaces/action-hubs/ICappedTokenTransfersHub.sol';
import {ICappedTokenTransfers} from 'src/interfaces/actions-builders/ICappedTokenTransfers.sol';

contract UnitCappedTokenTransfersHub is Test {
  CappedTokenTransfersHub public cappedTokenTransfersHub;
  address public safe;
  address public recipient;
  uint256 public epochLength;
  address[] public tokens;
  uint256[] public caps;

  function setUp() external {
    safe = makeAddr('safe');
    recipient = makeAddr('recipient');
    epochLength = 7 days;

    tokens.push(makeAddr('token1'));
    tokens.push(makeAddr('token2'));
    tokens.push(makeAddr('token3'));
    caps.push(100);
    caps.push(200);
    caps.push(300);

    cappedTokenTransfersHub = new CappedTokenTransfersHub(address(0), safe, recipient, tokens, caps, epochLength);
  }

  function test_ConstructorWhenCalled(address _safe, address _recipient, uint256 _epochLength) external {
    cappedTokenTransfersHub = new CappedTokenTransfersHub(address(0), _safe, _recipient, tokens, caps, _epochLength);

    // it sets the safe
    assertEq(address(cappedTokenTransfersHub.SAFE()), _safe);
    // it sets the recipient
    assertEq(cappedTokenTransfersHub.RECIPIENT(), _recipient);
    // it sets the epoch length
    assertEq(cappedTokenTransfersHub.EPOCH_LENGTH(), _epochLength);
    // it sets the starting timestamp
    assertEq(cappedTokenTransfersHub.STARTING_TIMESTAMP(), block.timestamp);
    // it sets the tokens and caps
    for (uint256 i = 0; i < tokens.length; i++) {
      assertEq(cappedTokenTransfersHub.cap(tokens[i]), caps[i]);
    }
  }

  function test_CreateNewActionBuilderWhenCalledByTheSafeOwner() external {
    vm.mockCall(address(safe), abi.encodeWithSelector(IOwnerManager.isOwner.selector), abi.encode(true));

    // it creates a new CappedTokenTransfers action builder
    address _actionBuilder = cappedTokenTransfersHub.createNewActionBuilder(tokens[0], 100);
    assertEq(ICappedTokenTransfers(_actionBuilder).FACTORY(), address(cappedTokenTransfersHub));
    assertNotEq(_actionBuilder, address(0));
  }

  function test_CreateNewActionBuilderWhenNotCalledByTheSafeOwner() external {
    vm.mockCall(address(safe), abi.encodeWithSelector(IOwnerManager.isOwner.selector), abi.encode(false));

    // It reverts
    vm.expectRevert(ISafeManageable.NotSafeOwner.selector);
    cappedTokenTransfersHub.createNewActionBuilder(tokens[0], 100);
  }

  modifier whenCalledByTheSafe() {
    vm.startPrank(safe);
    _;
    vm.stopPrank();
  }

  function test_UpdateStateWhenCalledByTheSafe(uint256 _amount) external whenCalledByTheSafe {
    _amount = bound(_amount, 0, cappedTokenTransfersHub.cap(tokens[0]));

    bytes memory data = abi.encode(_amount, tokens[0]);
    cappedTokenTransfersHub.updateState(data);

    // it increments the total spent
    assertEq(cappedTokenTransfersHub.totalSpent(tokens[0]), _amount);
  }

  function test_UpdateStateWhenTheCurrentEpochIsGreaterThanTheEpochOfTheState(uint256 _amount)
    external
    whenCalledByTheSafe
  {
    _amount = bound(_amount, 0, cappedTokenTransfersHub.cap(tokens[0]));

    // spend all the cap for this epoch
    cappedTokenTransfersHub.updateState(abi.encode(cappedTokenTransfersHub.cap(tokens[0]), tokens[0]));

    // move to the next epoch
    vm.warp(block.timestamp + epochLength + 1);

    bytes memory data = abi.encode(_amount, tokens[0]);
    cappedTokenTransfersHub.updateState(data);

    // it resets the total spent
    assertEq(cappedTokenTransfersHub.totalSpent(tokens[0]), _amount);
    // it updates the current epoch
    assertEq(cappedTokenTransfersHub.currentEpoch(), 1);
  }

  function test_UpdateStateWhenTheTotalSpentIsGreaterThanTheCap(uint256 _amount) external whenCalledByTheSafe {
    _amount = bound(_amount, cappedTokenTransfersHub.cap(tokens[0]) + 1, type(uint256).max);

    bytes memory data = abi.encode(_amount, tokens[0]);

    // it reverts
    vm.expectRevert(ICappedTokenTransfersHub.CapExceeded.selector);
    cappedTokenTransfersHub.updateState(data);
  }

  function test_UpdateStateWhenNotCalledByTheSafe() external {
    // It reverts
    vm.prank(makeAddr('notSafe'));
    vm.expectRevert(ISafeManageable.NotSafe.selector);
    cappedTokenTransfersHub.updateState(bytes(''));
  }
}
