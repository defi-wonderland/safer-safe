// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IOwnerManager} from '@safe-smart-account/interfaces/IOwnerManager.sol';
import {Test} from 'forge-std/Test.sol';
import {CappedTokenTransfersHub} from 'src/contracts/action-hubs/CappedTokenTransfersHub.sol';
import {ISafeManageable} from 'src/interfaces/ISafeManageable.sol';

import {ICappedTokenTransfersHub} from 'src/interfaces/action-hubs/ICappedTokenTransfersHub.sol';
import {IActionsBuilder} from 'src/interfaces/actions-builders/IActionsBuilder.sol';

contract UnitCappedTokenTransfersHub is Test {
  uint256 public constant EPOCH_LENGTH = 7 days;
  address public constant ZERO_SENTINEL = 0x0000000000000000000000fbb67FDa52D4Bfb8Bf;
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
    caps.push(100);

    cappedTokenTransfersHub = new CappedTokenTransfersHub(address(0), safe, recipient, tokens, caps, EPOCH_LENGTH);
  }

  function test_ConstructorWhenCalled(address _safe, address _recipient, uint256 _epochLength) external {
    _epochLength = bound(_epochLength, 1, type(uint256).max);
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
    address[] memory _tokens = cappedTokenTransfersHub.tokens();
    for (uint256 i = 0; i < tokens.length; i++) {
      assertEq(_tokens[i], tokens[i]);
      assertEq(cappedTokenTransfersHub.cap(tokens[i]), caps[i]);
    }
  }

  function test_ConstructorWhenTokensRegisteredContainADuplicatedToken(
    address _token,
    address _tokenB,
    uint256 _amountA,
    uint256 _amountB,
    uint256 _amountC
  ) external {
    vm.assume(_token != ZERO_SENTINEL);
    vm.assume(_tokenB != ZERO_SENTINEL);
    vm.assume(_token != _tokenB);

    tokens = new address[](3);
    tokens[0] = _token;
    tokens[1] = _tokenB;
    tokens[2] = _token;

    caps = new uint256[](3);
    caps[0] = _amountA;
    caps[1] = _amountB;
    caps[2] = _amountC;

    // it reverts
    vm.expectRevert(abi.encodeWithSelector(ICappedTokenTransfersHub.TokenAlreadyRegisteredInHub.selector, _token));
    new CappedTokenTransfersHub(address(0), safe, recipient, tokens, caps, EPOCH_LENGTH);
  }

  function test_ConstructorWhenTheEpochLengthIsZero() external {
    // it reverts
    vm.expectRevert(ICappedTokenTransfersHub.EpochLengthCannotBeZero.selector);
    new CappedTokenTransfersHub(address(0), safe, recipient, tokens, caps, 0);
  }

  modifier whenCalledByTheSafeOwner() {
    vm.mockCall(address(safe), abi.encodeWithSelector(IOwnerManager.isOwner.selector), abi.encode(true));
    _;
  }

  function test_CreateNewActionsBuilderWhenTheTokenIsNotRegisteredInTheHub(
    address _token,
    uint256 _amount
  ) external whenCalledByTheSafeOwner {
    vm.assume(_token != tokens[0] && _token != tokens[1] && _token != tokens[2]);
    vm.assume(_token != ZERO_SENTINEL);

    // it reverts
    vm.expectRevert(ICappedTokenTransfersHub.TokenNotRegisteredInHub.selector);
    cappedTokenTransfersHub.createNewActionsBuilder(_token, _amount);
  }

  function test_CreateNewActionsBuilderWhenTheTokenIsRegisteredInTheHub() external whenCalledByTheSafeOwner {
    // it creates a new CappedTokenTransfers actions builder
    address _actionsBuilder =
      cappedTokenTransfersHub.createNewActionsBuilder(tokens[0], cappedTokenTransfersHub.cap(tokens[0]));
    assertNotEq(_actionsBuilder, address(0));

    // it sets the hub address in the child contract
    assertEq(IActionsBuilder(_actionsBuilder).PARENT(), address(cappedTokenTransfersHub));
  }

  function test_CreateNewActionsBuilderWhenNotCalledByTheSafeOwner() external {
    vm.mockCall(address(safe), abi.encodeWithSelector(IOwnerManager.isOwner.selector), abi.encode(false));

    // It reverts
    vm.expectRevert(ISafeManageable.NotSafeOwner.selector);
    cappedTokenTransfersHub.createNewActionsBuilder(tokens[0], 100);
  }

  modifier whenCalledByTheSafe() {
    vm.startPrank(safe);
    _;
    vm.stopPrank();
  }

  function test_UpdateStateWhenCalledByTheSafe(uint256 _amount) external whenCalledByTheSafe {
    _amount = bound(_amount, 0, cappedTokenTransfersHub.cap(tokens[0]));

    cappedTokenTransfersHub.updateState(tokens[0], _amount);

    // it increments the total spent
    assertEq(cappedTokenTransfersHub.totalSpent(tokens[0]), _amount);
  }

  function test_UpdateStateWhenTheCurrentEpochIsGreaterThanTheEpochOfTheState(uint256 _amount)
    external
    whenCalledByTheSafe
  {
    _amount = bound(_amount, 0, cappedTokenTransfersHub.cap(tokens[0]));

    // spend all the cap for this epoch
    cappedTokenTransfersHub.updateState(tokens[0], cappedTokenTransfersHub.cap(tokens[0]));

    // move to the next epoch
    vm.warp(block.timestamp + EPOCH_LENGTH + 1);

    cappedTokenTransfersHub.updateState(tokens[0], _amount);

    // it resets the total spent
    assertEq(cappedTokenTransfersHub.totalSpent(tokens[0]), _amount);
    // it updates the current epoch
    assertEq(cappedTokenTransfersHub.currentEpoch(), 1);
  }

  function test_UpdateStateWhenTheTotalSpentIsGreaterThanTheCap(uint256 _amount) external whenCalledByTheSafe {
    _amount = bound(_amount, cappedTokenTransfersHub.cap(tokens[0]) + 1, type(uint256).max);

    // it reverts
    vm.expectRevert(ICappedTokenTransfersHub.CapExceeded.selector);
    cappedTokenTransfersHub.updateState(tokens[0], _amount);
  }

  function test_UpdateStateWhenNotCalledByTheSafe() external {
    // It reverts
    vm.prank(makeAddr('notSafe'));
    vm.expectRevert(ISafeManageable.NotSafe.selector);
    cappedTokenTransfersHub.updateState(tokens[0], 0);
  }

  function test_TokensWhenCalled() external view {
    // it returns the tokens
    address[] memory _tokens = cappedTokenTransfersHub.tokens();
    assertEq(_tokens.length, 3);
    assertEq(_tokens[0], tokens[0]);
    assertEq(_tokens[1], tokens[1]);
    assertEq(_tokens[2], tokens[2]);
  }

  function test_CapLeftWhenTokenDoesNotExist(address _token) external view {
    vm.assume(_token != tokens[0] && _token != tokens[1] && _token != tokens[2]);
    // it returns zero
    assertEq(cappedTokenTransfersHub.capLeft(_token), 0);
  }

  modifier whenTokenExists() {
    _;
  }

  function test_CapLeftWhenTheCurrentEpochIsGreaterThanTheEpochOfTheState(uint256 _amount) external whenTokenExists {
    _amount = bound(_amount, 1, cappedTokenTransfersHub.cap(tokens[0]));

    vm.prank(safe);
    cappedTokenTransfersHub.updateState(tokens[0], _amount);

    vm.warp(block.timestamp + EPOCH_LENGTH + 1);
    // it returns the full cap
    assertEq(cappedTokenTransfersHub.capLeft(tokens[0]), cappedTokenTransfersHub.cap(tokens[0]));
  }

  function test_CapLeftWhenTheCurrentEpochIsTheSameAsTheEpochOfTheState(uint256 _amount) external whenTokenExists {
    _amount = bound(_amount, 1, cappedTokenTransfersHub.cap(tokens[0]));

    vm.prank(safe);
    cappedTokenTransfersHub.updateState(tokens[0], _amount);

    // it returns the cap left for the token
    assertEq(cappedTokenTransfersHub.capLeft(tokens[0]), cappedTokenTransfersHub.cap(tokens[0]) - _amount);
  }
}
