// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {IOwnerManager} from '@safe-smart-account/interfaces/IOwnerManager.sol';
import {Test} from 'forge-std/Test.sol';
import {EnumerableSetLib} from 'solady/utils/EnumerableSetLib.sol';
import {CappedTokenTransfersHub} from 'src/contracts/action-hubs/CappedTokenTransfersHub.sol';
import {ISafeManageable} from 'src/interfaces/ISafeManageable.sol';
import {ICappedTokenTransfersHub} from 'src/interfaces/action-hubs/ICappedTokenTransfersHub.sol';

contract UnitCappedTokenTransfersHub is Test {
  uint256 public constant EPOCH_LENGTH = 7 days;

  CappedTokenTransfersHub public cappedTokenTransfersHub;
  address public safe = makeAddr('safe');
  address public recipient = makeAddr('recipient');
  address[] public tokens;
  uint256[] public caps;

  function setUp() external {
    tokens.push(makeAddr('token1'));
    tokens.push(makeAddr('token2'));
    tokens.push(makeAddr('token3'));
    caps.push(100);
    caps.push(200);
    caps.push(300);

    cappedTokenTransfersHub = new CappedTokenTransfersHub(safe, recipient, tokens, caps, EPOCH_LENGTH);
  }

  function test_ConstructorWhenCalled(address _safe, address _recipient, uint256 _epochLength) external {
    cappedTokenTransfersHub = new CappedTokenTransfersHub(_safe, _recipient, tokens, caps, _epochLength);

    // it sets the safe
    assertEq(address(cappedTokenTransfersHub.SAFE()), _safe);
    // it sets the recipient
    assertEq(cappedTokenTransfersHub.RECIPIENT(), _recipient);
    // it sets the epoch length
    assertEq(cappedTokenTransfersHub.EPOCH_LENGTH(), _epochLength);
    // it sets the starting timestamp
    assertEq(cappedTokenTransfersHub.STARTING_TIMESTAMP(), block.timestamp);

    // it sets the tokens and caps
    address[] memory _tokens = cappedTokenTransfersHub.tokens();
    uint256[] memory _caps = cappedTokenTransfersHub.caps();
    for (uint256 i = 0; i < _tokens.length; i++) {
      assertEq(_tokens[i], tokens[i]);
      assertEq(_caps[i], caps[i]);
    }
  }

  modifier whenCalledByTheSafeOwner() {
    vm.mockCall(address(safe), abi.encodeWithSelector(IOwnerManager.isOwner.selector), abi.encode(true));
    _;
  }

  function test_CreateNewActionBuilderWhenTheTokenIsNotRegisteredInTheHub(
    address _token,
    uint256 _amount
  ) external whenCalledByTheSafeOwner {
    vm.assume(_token != tokens[0] && _token != tokens[1] && _token != tokens[2]);

    // it reverts
    vm.expectRevert(ICappedTokenTransfersHub.TokenNotRegisteredInHub.selector);
    cappedTokenTransfersHub.createNewActionBuilder(_token, _amount);
  }

  function test_CreateNewActionBuilderWhenTheTokenIsRegisteredInTheHub() external whenCalledByTheSafeOwner {
    // it creates a new CappedTokenTransfers action builder
    address actionBuilder = cappedTokenTransfersHub.createNewActionBuilder(tokens[0], 100);
    assertNotEq(actionBuilder, address(0));
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
    _amount = bound(_amount, 0, caps[0]);

    bytes memory data = abi.encode(_amount, tokens[0]);
    cappedTokenTransfersHub.updateState(data);

    // it increments the total spent
    assertEq(cappedTokenTransfersHub.totalSpent(tokens[0]), _amount);
  }

  function test_UpdateStateWhenTheCurrentEpochIsGreaterThanTheEpochOfTheState(uint256 _amount)
    external
    whenCalledByTheSafe
  {
    _amount = bound(_amount, 0, caps[0]);

    // spend all the cap for this epoch
    cappedTokenTransfersHub.updateState(abi.encode(caps[0], tokens[0]));

    // move to the next epoch
    vm.warp(block.timestamp + EPOCH_LENGTH + 1);

    bytes memory data = abi.encode(_amount, tokens[0]);
    cappedTokenTransfersHub.updateState(data);

    // it resets the total spent
    assertEq(cappedTokenTransfersHub.totalSpent(tokens[0]), _amount);
    // it updates the current epoch
    assertEq(cappedTokenTransfersHub.currentEpoch(), 1);
  }

  function test_UpdateStateWhenTheTotalSpentIsGreaterThanTheCap(uint256 _amount) external whenCalledByTheSafe {
    _amount = bound(_amount, caps[0] + 1, type(uint256).max);

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

  function test_TokensWhenCalled() external view {
    // it returns the tokens
    address[] memory _tokens = cappedTokenTransfersHub.tokens();
    assertEq(_tokens.length, tokens.length);
    for (uint256 i = 0; i < _tokens.length; i++) {
      assertEq(_tokens[i], tokens[i]);
    }
  }

  function test_CapsWhenCalled() external view {
    // it returns the caps
    uint256[] memory _caps = cappedTokenTransfersHub.caps();
    assertEq(_caps.length, caps.length);
    for (uint256 i = 0; i < _caps.length; i++) {
      assertEq(_caps[i], caps[i]);
    }
  }

  function test_CapLeftWhenTokenDoesNotExist(address _token) external {
    vm.assume(_token != tokens[0] && _token != tokens[1] && _token != tokens[2]);
    // it reverts
    vm.expectRevert(EnumerableSetLib.IndexOutOfBounds.selector);
    cappedTokenTransfersHub.capLeft(_token);
  }

  modifier whenTokenExists() {
    _;
  }

  function test_CapLeftWhenTheCurrentEpochIsGreaterThanTheEpochOfTheState(uint256 _amount) external whenTokenExists {
    _amount = bound(_amount, 1, caps[0]);

    vm.prank(safe);
    cappedTokenTransfersHub.updateState(abi.encode(_amount, tokens[0]));

    vm.warp(block.timestamp + EPOCH_LENGTH + 1);
    // it returns the full cap
    assertEq(cappedTokenTransfersHub.capLeft(tokens[0]), caps[0]);
  }

  function test_CapLeftWhenTheCurrentEpochIsTheSameAsTheEpochOfTheState(uint256 _amount) external whenTokenExists {
    _amount = bound(_amount, 1, caps[0]);

    vm.prank(safe);
    cappedTokenTransfersHub.updateState(abi.encode(_amount, tokens[0]));

    // it returns the cap left for the token
    assertEq(cappedTokenTransfersHub.capLeft(tokens[0]), caps[0] - _amount);
  }
}
