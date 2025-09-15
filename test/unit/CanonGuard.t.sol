// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ActionHubForTest} from './mocks/ActionHubForTest.sol';
import {CanonGuardForTest} from './mocks/CanonGuardForTest.sol';
import {IOwnerManager} from '@safe-smart-account/interfaces/IOwnerManager.sol';
import {ISafe} from '@safe-smart-account/interfaces/ISafe.sol';
import {ICanonGuard} from 'contracts/CanonGuard.sol';
import {ISafeManageable} from 'contracts/SafeManageable.sol';
import {CappedTokenTransfersHub} from 'contracts/action-hubs/CappedTokenTransfersHub.sol';
import {Test} from 'forge-std/Test.sol';
import {IActionHub} from 'interfaces/action-hubs/IActionHub.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';

contract UnitCanonGuard is Test {
  CanonGuardForTest public canonGuard;

  uint256 public constant SHORT_TX_EXECUTION_DELAY = 1 hours;
  uint256 public constant LONG_TX_EXECUTION_DELAY = 7 days;
  uint256 public constant TX_EXPIRY_DELAY = 1 days;
  uint256 public constant ACTIONS_BUILDER_APPROVAL_DURATION = 7 days;
  uint256 public constant MAX_APPROVAL_DURATION = 4 * 365 days;
  address public immutable SAFE = makeAddr('SAFE');
  address public immutable MULTI_SEND_CALL_ONLY = makeAddr('MULTI_SEND_CALL_ONLY');
  address public immutable EMERGENCY_TRIGGER = makeAddr('EMERGENCY_TRIGGER');
  address public immutable EMERGENCY_CALLER = makeAddr('EMERGENCY_CALLER');
  address public immutable PARENT = makeAddr('PARENT');

  function setUp() public {
    canonGuard = new CanonGuardForTest(
      PARENT,
      SAFE,
      MULTI_SEND_CALL_ONLY,
      SHORT_TX_EXECUTION_DELAY,
      LONG_TX_EXECUTION_DELAY,
      TX_EXPIRY_DELAY,
      MAX_APPROVAL_DURATION,
      EMERGENCY_TRIGGER,
      EMERGENCY_CALLER
    );
  }

  function _mockAndExpect(address _target, bytes memory _call, bytes memory _returnData) internal {
    vm.mockCall(_target, _call, _returnData);
    vm.expectCall(_target, _call);
  }

  function _mockApprovedHashesForSigners(address[] memory _signers, uint256 _approvalValue) internal {
    for (uint256 _i = 0; _i < _signers.length; _i++) {
      bytes memory _callData = abi.encodeWithSelector(ISafe.approvedHashes.selector);
      bytes memory _returnData = abi.encode(_approvalValue);
      _mockAndExpect(SAFE, _callData, _returnData);
    }
  }

  function _assumeFuzzable(address _address) internal pure {
    assumeNotForgeAddress(_address);
    assumeNotZeroAddress(_address);
    assumeNotPrecompile(_address);
  }

  function _modifyIsChildReturnValue(address _actionHub, address _actionsBuilder, bool _returnValue) internal {
    vm.mockCall(
      _actionHub, abi.encodeWithSelector(IActionHub.isChild.selector, _actionsBuilder), abi.encode(_returnValue)
    );
  }

  function test_ConstructorWhenPassingValidParameters(
    address _safe,
    address _multiSendCallOnly,
    uint256 _shortTxExecutionDelay,
    uint256 _longTxExecutionDelay,
    uint256 _txExpiryDelay,
    uint256 _maxApprovalDuration
  ) external {
    _txExpiryDelay = bound(_txExpiryDelay, canonGuard.MIN_EXPIRY_TIME(), type(uint128).max);
    _maxApprovalDuration = bound(_maxApprovalDuration, canonGuard.MIN_EXPIRY_TIME(), type(uint256).max);
    _shortTxExecutionDelay = bound(_shortTxExecutionDelay, 0, type(uint128).max - 1);
    _longTxExecutionDelay = bound(_longTxExecutionDelay, _shortTxExecutionDelay, type(uint128).max);

    canonGuard = new CanonGuardForTest(
      PARENT,
      _safe,
      _multiSendCallOnly,
      _shortTxExecutionDelay,
      _longTxExecutionDelay,
      _txExpiryDelay,
      _maxApprovalDuration,
      EMERGENCY_TRIGGER,
      EMERGENCY_CALLER
    );
    assertEq(address(ISafeManageable(address(canonGuard)).SAFE()), _safe);
    assertEq(canonGuard.MULTI_SEND_CALL_ONLY(), _multiSendCallOnly);
    assertEq(canonGuard.SHORT_TX_EXECUTION_DELAY(), _shortTxExecutionDelay);
    assertEq(canonGuard.LONG_TX_EXECUTION_DELAY(), _longTxExecutionDelay);
    assertEq(canonGuard.TX_EXPIRY_DELAY(), _txExpiryDelay);
    assertEq(canonGuard.MAX_APPROVAL_DURATION(), _maxApprovalDuration);
    assertEq(canonGuard.PARENT(), PARENT);
  }

  function test_ConstructorWhenTheTransactionExpiryDelayIsLessThanTheMinimumExpiryTime(uint256 _delay) external {
    _delay = bound(_delay, 0, canonGuard.MIN_EXPIRY_TIME() - 1);

    // it reverts
    vm.expectRevert(ICanonGuard.TxExpiryDelayCannotBeLessThanMin.selector);
    new CanonGuardForTest(
      PARENT,
      SAFE,
      MULTI_SEND_CALL_ONLY,
      SHORT_TX_EXECUTION_DELAY,
      LONG_TX_EXECUTION_DELAY,
      _delay,
      MAX_APPROVAL_DURATION,
      EMERGENCY_TRIGGER,
      EMERGENCY_CALLER
    );
  }

  function test_ConstructorWhenTheMaximumApprovalDurationIsLessThanTheMinimumExpiryTime(uint256 _duration) external {
    _duration = bound(_duration, 0, canonGuard.MIN_EXPIRY_TIME() - 1);

    // it reverts
    vm.expectRevert(ICanonGuard.MaxApprovalDurationCannotBeLessThanMin.selector);
    new CanonGuardForTest(
      PARENT,
      SAFE,
      MULTI_SEND_CALL_ONLY,
      SHORT_TX_EXECUTION_DELAY,
      LONG_TX_EXECUTION_DELAY,
      TX_EXPIRY_DELAY,
      _duration,
      EMERGENCY_TRIGGER,
      EMERGENCY_CALLER
    );
  }

  function test_ConstructorWhenTheShortExecutionDelayIsGreaterThanTheLongExecutionDelay(
    uint256 _shortTxExecutionDelay,
    uint256 _longTxExecutionDelay
  ) external {
    _longTxExecutionDelay = bound(_longTxExecutionDelay, 0, type(uint256).max - 1);
    _shortTxExecutionDelay = bound(_shortTxExecutionDelay, _longTxExecutionDelay + 1, type(uint256).max);

    // it reverts
    vm.expectRevert(ICanonGuard.ShortDelayCannotBeGreaterThanLongDelay.selector);
    new CanonGuardForTest(
      PARENT,
      SAFE,
      MULTI_SEND_CALL_ONLY,
      _shortTxExecutionDelay,
      _longTxExecutionDelay,
      TX_EXPIRY_DELAY,
      MAX_APPROVAL_DURATION,
      EMERGENCY_TRIGGER,
      EMERGENCY_CALLER
    );
  }

  function test_ConstructorWhenTxExpiryDelayIsGreaterThanMax(uint256 _txExpiryDelay) external {
    _txExpiryDelay = bound(_txExpiryDelay, uint256(type(uint128).max) + 1, type(uint256).max);

    // it reverts
    vm.expectRevert(ICanonGuard.TxExpiryDelayCannotBeGreaterThanMax.selector);
    new CanonGuardForTest(
      PARENT,
      SAFE,
      MULTI_SEND_CALL_ONLY,
      SHORT_TX_EXECUTION_DELAY,
      LONG_TX_EXECUTION_DELAY,
      _txExpiryDelay,
      MAX_APPROVAL_DURATION,
      EMERGENCY_TRIGGER,
      EMERGENCY_CALLER
    );
  }

  function test_ConstructorWhenLongDelayIsGreaterThanMax(uint256 _longTxExecutionDelay) external {
    _longTxExecutionDelay = bound(_longTxExecutionDelay, uint256(type(uint128).max) + 1, type(uint256).max);

    // it reverts
    vm.expectRevert(ICanonGuard.LongDelayCannotBeGreaterThanMax.selector);
    new CanonGuardForTest(
      PARENT,
      SAFE,
      MULTI_SEND_CALL_ONLY,
      SHORT_TX_EXECUTION_DELAY,
      _longTxExecutionDelay,
      TX_EXPIRY_DELAY,
      MAX_APPROVAL_DURATION,
      EMERGENCY_TRIGGER,
      EMERGENCY_CALLER
    );
  }

  modifier whenCallerIsSafe() {
    vm.startPrank(SAFE);
    _;
    vm.stopPrank();
  }

  function test_ApproveActionsBuilderOrHubWhenCallerIsSafe(uint256 _approvalDuration, address _actionsBuilder) external {
    _approvalDuration = bound(_approvalDuration, 0, MAX_APPROVAL_DURATION);

    vm.expectEmit(address(canonGuard));
    emit ICanonGuard.ActionsBuilderOrHubApproved(
      _actionsBuilder, _approvalDuration, block.timestamp + _approvalDuration
    );

    vm.prank(SAFE);
    canonGuard.approveActionsBuilderOrHub(_actionsBuilder, _approvalDuration);

    assertEq(canonGuard.approvalExpiries(_actionsBuilder), block.timestamp + _approvalDuration);
  }

  function test_ApproveActionsBuilderOrHubWhenApprovalDurationIsGreaterThanMaxApprovalDuration(
    uint256 _approvalDuration
  ) external whenCallerIsSafe {
    _approvalDuration = bound(_approvalDuration, canonGuard.MAX_APPROVAL_DURATION() + 1, type(uint256).max);

    // it reverts with InvalidApprovalDuration
    vm.expectRevert(ICanonGuard.InvalidApprovalDuration.selector);
    canonGuard.approveActionsBuilderOrHub(address(0), _approvalDuration);
  }

  function test_ApproveActionsBuilderOrHubWhenExtendingApproval(
    address _actionsBuilder,
    uint256 _previousApprovalExpiry,
    uint256 _newApprovalDuration
  ) external {
    _newApprovalDuration = bound(_newApprovalDuration, 0, MAX_APPROVAL_DURATION);

    canonGuard.mockApprovalExpiry(_actionsBuilder, _previousApprovalExpiry);

    assertEq(canonGuard.approvalExpiries(_actionsBuilder), _previousApprovalExpiry);

    vm.expectEmit(address(canonGuard));
    emit ICanonGuard.ActionsBuilderOrHubApproved(
      _actionsBuilder, _newApprovalDuration, block.timestamp + _newApprovalDuration
    );

    vm.prank(SAFE);
    canonGuard.approveActionsBuilderOrHub(_actionsBuilder, _newApprovalDuration);

    assertEq(canonGuard.approvalExpiries(_actionsBuilder), block.timestamp + _newApprovalDuration);
  }

  function test_ApproveActionsBuilderOrHubWhenCallerIsNotSafe(
    address _caller,
    uint256 _approvalDuration,
    address _actionsBuilder
  ) external {
    vm.assume(_caller != SAFE);
    vm.expectRevert(ISafeManageable.NotSafe.selector);
    vm.prank(_caller);
    canonGuard.approveActionsBuilderOrHub(_actionsBuilder, _approvalDuration);
  }

  modifier whenCallerIsSafeOwner() {
    _mockAndExpect(SAFE, abi.encodeWithSelector(IOwnerManager.isOwner.selector), abi.encode(true));
    _;
  }

  function test_QueueTransactionWhenQueueingPreApprovedAction(
    address _caller,
    address _actionsBuilder
  ) external whenCallerIsSafeOwner givenActionsBuilderIsApproved(_actionsBuilder) {
    _assumeFuzzable(_actionsBuilder);

    _mockAndExpect(
      address(_actionsBuilder),
      abi.encodeWithSelector(IActionsBuilder.getActions.selector),
      abi.encode(new IActionsBuilder.Action[](0))
    );

    _mockAndExpect(
      address(_actionsBuilder), abi.encodeWithSelector(IActionsBuilder.IS_BUILDER.selector), abi.encode(true)
    );

    // it emits TransactionQueued event
    vm.expectEmit(address(canonGuard));
    emit ICanonGuard.TransactionQueued(address(0), _actionsBuilder, true);

    vm.prank(_caller);
    canonGuard.queueTransaction(_actionsBuilder);

    // Verify transaction info using the new interface
    (bytes memory _actionsData, uint256 _executableAt, uint256 _expiresAt) =
      canonGuard.queuedTransactions(_actionsBuilder);

    // it sets transaction info
    assertEq(_actionsData, abi.encode(new IActionsBuilder.Action[](0)));
    // it sets executable time at block timestamp plus short delay
    assertEq(_executableAt, block.timestamp + SHORT_TX_EXECUTION_DELAY);
    // it sets expiry time at executable time plus expiry delay
    assertEq(_expiresAt, block.timestamp + SHORT_TX_EXECUTION_DELAY + TX_EXPIRY_DELAY);
  }

  function test_QueueTransactionWhenQueueingNotApprovedAction(
    address _caller,
    address _target,
    uint256 _value,
    address _actionsBuilder,
    bytes memory _data
  ) external whenCallerIsSafeOwner {
    _assumeFuzzable(_actionsBuilder);

    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = IActionsBuilder.Action({target: _target, value: _value, data: _data});

    _mockAndExpect(
      address(_actionsBuilder), abi.encodeWithSelector(IActionsBuilder.getActions.selector), abi.encode(_actions)
    );

    _mockAndExpect(
      address(_actionsBuilder), abi.encodeWithSelector(IActionsBuilder.IS_BUILDER.selector), abi.encode(true)
    );

    // it emits TransactionQueued event
    vm.expectEmit(address(canonGuard));
    emit ICanonGuard.TransactionQueued(address(0), _actionsBuilder, false);

    vm.prank(_caller);
    canonGuard.queueTransaction(_actionsBuilder);

    // Verify transaction info using the new interface
    (bytes memory _actionsData, uint256 _executableAt, uint256 _expiresAt) =
      canonGuard.queuedTransactions(_actionsBuilder);

    // it sets transaction info
    assertEq(_actionsData, abi.encode(_actions));
    // it sets executable time at block timestamp plus long delay
    assertEq(_executableAt, block.timestamp + LONG_TX_EXECUTION_DELAY);
    // it sets expiry time at executable time plus expiry delay
    assertEq(_expiresAt, block.timestamp + LONG_TX_EXECUTION_DELAY + TX_EXPIRY_DELAY);
  }

  function test_QueueTransactionWhenAddressIsNotAnActionsBuilder(address _parent) external whenCallerIsSafeOwner {
    address _actionHub = address(new ActionHubForTest(_parent));

    // it reverts
    vm.expectRevert(ICanonGuard.NotAnActionsBuilder.selector);
    canonGuard.queueTransaction(_actionHub);
  }

  function test_QueueTransactionWhenAddressDoesNotRespondToIS_BUILDER(
    address _recipient,
    uint256 _epochLength
  ) external whenCallerIsSafeOwner {
    vm.assume(_epochLength > 0);
    address[] memory _tokens = new address[](1);
    _tokens[0] = makeAddr('token');

    uint256[] memory _caps = new uint256[](1);
    _caps[0] = 100;

    address _actionHub =
      address(new CappedTokenTransfersHub(address(0), SAFE, _recipient, _tokens, _caps, _epochLength));

    // it reverts
    vm.expectRevert(ICanonGuard.NotAnActionsBuilder.selector);
    canonGuard.queueTransaction(_actionHub);
  }

  function test_QueueTransactionWhenTransactionIsAlreadyQueuedButExpired(
    address _caller,
    address _target,
    uint256 _value,
    address _actionsBuilder,
    bytes memory _data
  ) external whenCallerIsSafeOwner {
    _assumeFuzzable(_actionsBuilder);

    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = IActionsBuilder.Action({target: _target, value: _value, data: _data});

    _mockAndExpect(
      address(_actionsBuilder), abi.encodeWithSelector(IActionsBuilder.getActions.selector), abi.encode(_actions)
    );

    _mockAndExpect(
      address(_actionsBuilder), abi.encodeWithSelector(IActionsBuilder.IS_BUILDER.selector), abi.encode(true)
    );

    vm.prank(_caller);
    canonGuard.queueTransaction(_actionsBuilder);

    // Move time forward past expiry
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY + TX_EXPIRY_DELAY + 1);

    vm.prank(_caller);
    canonGuard.queueTransaction(_actionsBuilder);

    // Verify transaction info using the new interface
    (,, uint256 _expiresAt) = canonGuard.queuedTransactions(_actionsBuilder);

    // it should queue the transaction
    assertEq(_expiresAt, block.timestamp + LONG_TX_EXECUTION_DELAY + TX_EXPIRY_DELAY);
  }

  function test_QueueTransactionWhenCallerIsNotSafeOwner(
    address _caller,
    address _actionsBuilder
  ) external givenCallerIsNotSafeOwner(_caller) {
    // it reverts with NotSafeOwner
    vm.expectRevert(ISafeManageable.NotSafeOwner.selector);
    vm.prank(_caller);
    canonGuard.queueTransaction(_actionsBuilder);
  }

  function test_QueueTransactionWhenTransactionIsAlreadyQueuedAndNotExpired(
    address _caller,
    address _actionsBuilder,
    uint256 _expiry
  ) external givenCallerIsSafeOwner(_caller) {
    _expiry = bound(_expiry, block.timestamp + 1, block.timestamp + TX_EXPIRY_DELAY);

    _mockAndExpect(
      address(_actionsBuilder), abi.encodeWithSelector(IActionsBuilder.IS_BUILDER.selector), abi.encode(true)
    );

    canonGuard.mockTransaction(_actionsBuilder, abi.encode(new IActionsBuilder.Action[](0)), block.timestamp, _expiry);

    // it reverts with TransactionAlreadyQueued
    vm.expectRevert(abi.encodeWithSelector(ICanonGuard.TransactionAlreadyQueued.selector, _actionsBuilder));
    canonGuard.queueTransaction(_actionsBuilder);
  }

  function test_QueueHubTransactionWhenHubIsNotAChild(
    address _actionHub,
    address _actionsBuilder
  ) external whenCallerIsSafeOwner {
    _assumeFuzzable(_actionHub);
    _assumeFuzzable(_actionsBuilder);
    _modifyIsChildReturnValue(_actionHub, _actionsBuilder, false);

    // it reverts with InvalidHubOrActionsBuilder
    vm.expectRevert(ICanonGuard.InvalidHubOrActionsBuilder.selector);
    canonGuard.queueHubTransaction(_actionHub, _actionsBuilder);
  }

  function test_QueueHubTransactionWhenQueueingPreApprovedAction(
    address _caller,
    address _actionHub,
    address _actionsBuilder
  ) external whenCallerIsSafeOwner givenActionsBuilderIsApproved(_actionHub) {
    _assumeFuzzable(_actionHub);
    _assumeFuzzable(_actionsBuilder);
    _modifyIsChildReturnValue(_actionHub, _actionsBuilder, true);

    _mockAndExpect(
      address(_actionsBuilder),
      abi.encodeWithSelector(IActionsBuilder.getActions.selector),
      abi.encode(new IActionsBuilder.Action[](0))
    );

    // it emits TransactionQueued event
    vm.expectEmit(address(canonGuard));
    emit ICanonGuard.TransactionQueued(_actionHub, _actionsBuilder, true);

    vm.prank(_caller);
    canonGuard.queueHubTransaction(_actionHub, _actionsBuilder);

    // Verify transaction info using the new interface
    (bytes memory _actionsData, uint256 _executableAt, uint256 _expiresAt) =
      canonGuard.queuedTransactions(_actionsBuilder);

    // it sets transaction info
    assertEq(_actionsData, abi.encode(new IActionsBuilder.Action[](0)));
    // it sets executable at to block timestamp plus short delay
    assertEq(_executableAt, block.timestamp + SHORT_TX_EXECUTION_DELAY);
    // it sets expiry time
    assertEq(_expiresAt, block.timestamp + SHORT_TX_EXECUTION_DELAY + TX_EXPIRY_DELAY);
  }

  function test_QueueHubTransactionWhenQueueingNotApprovedAction(
    address _caller,
    address _target,
    uint256 _value,
    address _actionHub,
    address _actionsBuilder,
    bytes memory _data
  ) external whenCallerIsSafeOwner {
    _assumeFuzzable(_actionsBuilder);

    _modifyIsChildReturnValue(_actionHub, _actionsBuilder, true);
    _assumeFuzzable(_actionHub);
    _assumeFuzzable(_actionsBuilder);

    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = IActionsBuilder.Action({target: _target, value: _value, data: _data});

    _mockAndExpect(
      address(_actionsBuilder), abi.encodeWithSelector(IActionsBuilder.getActions.selector), abi.encode(_actions)
    );

    // it emits TransactionQueued event
    vm.expectEmit(address(canonGuard));
    emit ICanonGuard.TransactionQueued(_actionHub, _actionsBuilder, false);

    vm.prank(_caller);
    canonGuard.queueHubTransaction(_actionHub, _actionsBuilder);

    // Verify transaction info using the new interface
    (bytes memory _actionsData, uint256 _executableAt, uint256 _expiresAt) =
      canonGuard.queuedTransactions(_actionsBuilder);

    // it sets transaction info
    assertEq(_actionsData, abi.encode(_actions));
    // it sets executable at to block timestamp plus long delay
    assertEq(_executableAt, block.timestamp + LONG_TX_EXECUTION_DELAY);
    // it sets expiry time
    assertEq(_expiresAt, block.timestamp + LONG_TX_EXECUTION_DELAY + TX_EXPIRY_DELAY);
  }

  function test_QueueHubTransactionWhenTransactionIsAlreadyQueuedButExpired(
    address _caller,
    address _actionHub,
    address _actionsBuilder,
    address _target,
    uint256 _value,
    bytes memory _data
  ) external givenCallerIsSafeOwner(_caller) givenActionsBuilderIsApproved(_actionHub) {
    _assumeFuzzable(_actionsBuilder);
    _assumeFuzzable(_actionHub);
    _assumeFuzzable(_caller);

    _modifyIsChildReturnValue(_actionHub, _actionsBuilder, true);

    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = IActionsBuilder.Action({target: _target, value: _value, data: _data});

    _mockAndExpect(
      address(_actionsBuilder), abi.encodeWithSelector(IActionsBuilder.getActions.selector), abi.encode(_actions)
    );

    vm.prank(_caller);
    canonGuard.queueHubTransaction(_actionHub, _actionsBuilder);

    // Move time forward past expiry
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY + TX_EXPIRY_DELAY + 1);

    vm.prank(_caller);
    canonGuard.queueHubTransaction(_actionHub, _actionsBuilder);

    // Verify transaction info using the new interface
    (,, uint256 _expiresAt) = canonGuard.queuedTransactions(_actionsBuilder);

    // it should queue the transaction
    assertEq(_expiresAt, block.timestamp + LONG_TX_EXECUTION_DELAY + TX_EXPIRY_DELAY);
  }

  function test_QueueHubTransactionWhenCallerIsNotSafeOwner(
    address _caller,
    address _actionHub,
    address _actionsBuilder
  ) external givenCallerIsNotSafeOwner(_caller) {
    _assumeFuzzable(_caller);
    _assumeFuzzable(_actionHub);
    _assumeFuzzable(_actionsBuilder);
    _modifyIsChildReturnValue(_actionHub, _actionsBuilder, true);

    // it reverts with NotSafeOwner
    vm.expectRevert(ISafeManageable.NotSafeOwner.selector);
    vm.prank(_caller);
    canonGuard.queueHubTransaction(_actionHub, _actionsBuilder);
  }

  function test_QueueHubTransactionWhenTransactionIsAlreadyQueuedAndNotExpired(
    address _caller,
    address _actionHub,
    address _actionsBuilder,
    uint256 _expiry
  ) external givenCallerIsSafeOwner(_caller) givenActionsBuilderIsApproved(_actionHub) {
    _assumeFuzzable(_actionHub);
    _assumeFuzzable(_actionsBuilder);
    _assumeFuzzable(_caller);

    _modifyIsChildReturnValue(_actionHub, _actionsBuilder, true);

    _expiry = bound(_expiry, block.timestamp + 1, block.timestamp + TX_EXPIRY_DELAY);

    canonGuard.mockTransaction(_actionsBuilder, abi.encode(new IActionsBuilder.Action[](0)), block.timestamp, _expiry);

    // it reverts with TransactionAlreadyQueued
    vm.expectRevert(abi.encodeWithSelector(ICanonGuard.TransactionAlreadyQueued.selector, _actionsBuilder));
    vm.prank(_caller);
    canonGuard.queueHubTransaction(_actionHub, _actionsBuilder);
  }

  function test_ExecuteTransactionWhenTransactionIsExpired(
    address _caller,
    address _actionsBuilder,
    IActionsBuilder.Action calldata _action,
    ICanonGuard.TransactionInfo memory _txInfo
  ) external {
    // Ensure expiresAt is valid and not 0, and that it's less than type(uint64).max - 1
    _txInfo.expiresAt = bound(_txInfo.expiresAt, 1, type(uint64).max - 1);
    _txInfo.executableAt = bound(_txInfo.executableAt, 0, block.timestamp);
    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = _action;
    bytes memory _actionsData = abi.encode(_actions);

    // Mock SAFE contract calls
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.nonce.selector), abi.encode(1));
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.getTransactionHash.selector), abi.encode(bytes32(0)));
    _mockAndExpect(SAFE, abi.encodeWithSelector(IOwnerManager.getOwners.selector), abi.encode(new address[](0)));

    canonGuard.mockTransaction(_actionsBuilder, _actionsData, _txInfo.executableAt, _txInfo.expiresAt);

    // Move time forward past expiry
    vm.warp(_txInfo.expiresAt + 1);

    vm.expectRevert(ICanonGuard.TransactionExpired.selector);
    vm.prank(_caller);
    canonGuard.executeTransaction(_actionsBuilder);
  }

  function test_ExecuteTransactionWhenApprovedTransactionIsNotYetExecutable(
    address _caller,
    address _actionsBuilder,
    IActionsBuilder.Action calldata _action,
    ICanonGuard.TransactionInfo memory _txInfo
  ) external {
    _txInfo.expiresAt = bound(_txInfo.expiresAt, block.timestamp + 1, type(uint256).max);
    _txInfo.executableAt = bound(_txInfo.executableAt, block.timestamp + 1, type(uint256).max);

    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = _action;
    bytes memory _actionsData = abi.encode(_actions);

    // Mock SAFE contract calls
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.nonce.selector), abi.encode(1));
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.getTransactionHash.selector), abi.encode(bytes32(0)));
    _mockAndExpect(SAFE, abi.encodeWithSelector(IOwnerManager.getOwners.selector), abi.encode(new address[](0)));

    // Mock a transaction that is not yet executable
    canonGuard.mockTransaction(
      _actionsBuilder, // actionsBuilder
      _actionsData, // actionsData
      _txInfo.executableAt, // executableAt
      _txInfo.expiresAt // expiresAt
    );

    vm.expectRevert(ICanonGuard.TransactionNotYetExecutable.selector);
    vm.prank(_caller);
    canonGuard.executeTransaction(_actionsBuilder);
  }

  function test_ExecuteTransactionWhenTransactionIsNotQueued(address _actionsBuilder) external {
    _assumeFuzzable(_actionsBuilder);

    // it reverts with TransactionNotQueued
    vm.expectRevert(ICanonGuard.NoTransactionQueued.selector);
    canonGuard.executeTransaction(_actionsBuilder);
  }

  function test_ExecuteTransactionWhenApprovedTransactionIsValid(
    address _caller,
    address _actionsBuilder,
    IActionsBuilder.Action calldata _action,
    ICanonGuard.TransactionInfo memory _txInfo
  ) external {
    _txInfo.expiresAt = bound(_txInfo.expiresAt, block.timestamp + 1, type(uint256).max);
    _txInfo.executableAt = bound(_txInfo.executableAt, block.timestamp - 1, block.timestamp);
    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = _action;
    bytes memory _actionsData = abi.encode(_actions);

    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.nonce.selector), abi.encode(1));
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.getTransactionHash.selector), abi.encode(bytes32(0)));
    _mockAndExpect(SAFE, abi.encodeWithSelector(IOwnerManager.getOwners.selector), abi.encode(new address[](0)));

    // it executes transaction
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.execTransaction.selector), abi.encode(true));

    canonGuard.mockTransaction(
      _actionsBuilder, // actionsBuilder
      _actionsData, // actionsData
      _txInfo.executableAt, // executableAt
      _txInfo.expiresAt // expiresAt
    );

    // it emits TransactionExecuted event
    vm.expectEmit(address(canonGuard));
    emit ICanonGuard.TransactionExecuted(_actionsBuilder, bytes32(0), new address[](0));

    vm.prank(_caller);
    canonGuard.executeTransaction(_actionsBuilder);

    // it deletes transaction from queue
    (bytes memory __actionsData, uint256 _executableAt, uint256 _expiresAt) =
      canonGuard.queuedTransactions(_actionsBuilder);
    assertEq(__actionsData, bytes(''));
    assertEq(_executableAt, 0);
    assertEq(_expiresAt, 0);
  }

  modifier whenTransactionExists() {
    _;
  }

  function test_GetSafeTransactionHashWhenTransactionExists(
    address _actionsBuilder,
    IActionsBuilder.Action memory _action,
    ICanonGuard.TransactionInfo memory _txInfo,
    uint256 _safeNonce,
    bytes32 _expectedHash
  ) external {
    // Ensure expiresAt is not 0 to avoid NoTransactionQueued error
    _txInfo.expiresAt = bound(_txInfo.expiresAt, 1, type(uint256).max);

    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = _action;
    bytes memory _actionsData = abi.encode(_actions);
    canonGuard.mockTransaction(_actionsBuilder, _actionsData, _txInfo.executableAt, _txInfo.expiresAt);

    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.nonce.selector), abi.encode(_safeNonce));
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.getTransactionHash.selector), abi.encode(_expectedHash));

    bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(_actionsBuilder);
    assertEq(_safeTxHash, _expectedHash);
  }

  function test_GetSafeTransactionHashWhenGettingHashWithNonce(
    address _actionsBuilder,
    IActionsBuilder.Action memory _action,
    ICanonGuard.TransactionInfo memory _txInfo,
    uint256 _safeNonce,
    bytes32 _expectedHash
  ) external {
    // Ensure expiresAt is not 0 to avoid NoTransactionQueued error
    _txInfo.expiresAt = bound(_txInfo.expiresAt, 1, type(uint256).max);

    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = _action;
    bytes memory _actionsData = abi.encode(_actions);
    canonGuard.mockTransaction(_actionsBuilder, _actionsData, _txInfo.executableAt, _txInfo.expiresAt);

    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.getTransactionHash.selector), abi.encode(_expectedHash));

    bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(_actionsBuilder, _safeNonce);
    assertEq(_safeTxHash, _expectedHash);
  }

  function test_GetSafeTransactionHashWhenTransactionDoesNotExist(address _actionsBuilder) external {
    _assumeFuzzable(_actionsBuilder);

    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.nonce.selector), abi.encode(1));

    // it reverts with NoTransactionQueued
    vm.expectRevert(ICanonGuard.NoTransactionQueued.selector);
    canonGuard.getSafeTransactionHash(_actionsBuilder);
  }

  function test_GetApprovedHashSignersWhenTransactionExists(
    address _signer1,
    address _signer2,
    address _actionsBuilder,
    IActionsBuilder.Action memory _action,
    ICanonGuard.TransactionInfo memory _txInfo,
    uint256 _safeNonce
  ) external {
    // Ensure expiresAt is not 0 to avoid NoTransactionQueued error
    _txInfo.expiresAt = bound(_txInfo.expiresAt, 1, type(uint256).max);

    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = _action;
    bytes memory _actionsData = abi.encode(_actions);
    canonGuard.mockTransaction(_actionsBuilder, _actionsData, _txInfo.executableAt, _txInfo.expiresAt);

    address[] memory _signers = new address[](2);
    _signers[0] = _signer1;
    _signers[1] = _signer2;
    _mockApprovedHashesForSigners(_signers, 1);

    _mockAndExpect(SAFE, abi.encodeWithSelector(IOwnerManager.getOwners.selector), abi.encode(_signers));
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.getTransactionHash.selector), abi.encode(bytes32(0)));

    // it returns approved signers
    address[] memory _approvedSigners = canonGuard.getApprovedHashSigners(_actionsBuilder, _safeNonce);
    assertEq(_approvedSigners, _signers);
  }

  function test_GetApprovedHashSignersWhenTransactionDoesNotExist(address _actionsBuilder, uint256 _nonce) external {
    _assumeFuzzable(_actionsBuilder);

    // it reverts with NoTransactionQueued
    vm.expectRevert(ICanonGuard.NoTransactionQueued.selector);
    canonGuard.getApprovedHashSigners(_actionsBuilder, _nonce);
  }

  function test_GetSafeNonceReturnsCorrectNonce(uint256 _nonce) external {
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.nonce.selector), abi.encode(_nonce));

    assertEq(canonGuard.getSafeNonce(), _nonce);
  }

  modifier givenCallerIsSafeOwner(address _caller) {
    _mockAndExpect(SAFE, abi.encodeWithSelector(IOwnerManager.isOwner.selector), abi.encode(true));
    _;
  }

  modifier givenCallerIsNotSafeOwner(address _caller) {
    _mockAndExpect(SAFE, abi.encodeWithSelector(IOwnerManager.isOwner.selector), abi.encode(false));
    _;
  }

  modifier givenActionsBuilderIsApproved(address _actionsBuilder) {
    vm.prank(SAFE);
    canonGuard.approveActionsBuilderOrHub(_actionsBuilder, ACTIONS_BUILDER_APPROVAL_DURATION);
    _;
  }
}
