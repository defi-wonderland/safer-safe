// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {CanonGuardForTest} from './mocks/CanonGuardForTest.sol';
import {IOwnerManager} from '@safe-smart-account/interfaces/IOwnerManager.sol';
import {ISafe} from '@safe-smart-account/interfaces/ISafe.sol';
import {Enum} from '@safe-smart-account/libraries/Enum.sol';
import {MultiSendCallOnly} from '@safe-smart-account/libraries/MultiSendCallOnly.sol';
import {ICanonGuard} from 'contracts/CanonGuard.sol';
import {IEmergencyModeHook} from 'contracts/EmergencyModeHook.sol';
import {ISafeManageable} from 'contracts/SafeManageable.sol';
import {Test} from 'forge-std/Test.sol';
import {IActionHub} from 'interfaces/action-hubs/IActionHub.sol';
import {IActionHubChild} from 'interfaces/action-hubs/IActionHubChild.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';

contract UnitCanonGuard is Test {
  CanonGuardForTest public canonGuard;

  uint256 public constant SHORT_TX_EXECUTION_DELAY = 1 hours;
  uint256 public constant LONG_TX_EXECUTION_DELAY = 7 days;
  uint256 public constant TX_EXPIRY_DELAY = 1 hours;
  uint256 public constant ACTIONS_BUILDER_APPROVAL_DURATION = 7 days;
  uint256 public constant MAX_APPROVAL_DURATION = 4 * 365 days;
  address public immutable SAFE = makeAddr('SAFE');
  address public immutable MULTI_SEND_CALL_ONLY = makeAddr('MULTI_SEND_CALL_ONLY');
  address public immutable EMERGENCY_TRIGGER = makeAddr('EMERGENCY_TRIGGER');
  address public immutable EMERGENCY_CALLER = makeAddr('EMERGENCY_CALLER');
  address public immutable PARENT = makeAddr('PARENT');
  address public constant ENUMERABLE_SET_LIST_SENTINEL = address(0xfbb67fda52d4bfb8bf);

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
    vm.assume(_address != ENUMERABLE_SET_LIST_SENTINEL);
  }

  function test_Constructor_WhenPassingValidParameters(
    address _safe,
    address _multiSendCallOnly,
    uint256 _shortTxExecutionDelay,
    uint256 _longTxExecutionDelay,
    uint256 _txExpiryDelay,
    uint256 _maxApprovalDuration
  ) external {
    _txExpiryDelay = bound(_txExpiryDelay, 1 hours, type(uint128).max);
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

  function test_Constructor_WhenTheShortExecutionDelayIsGreaterThanTheLongExecutionDelay(
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

  function test_Constructor_WhenTxExpiryDelayIsGreaterThanMax(uint256 _txExpiryDelay) external {
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

  function test_Constructor_WhenLongDelayIsGreaterThanMax(uint256 _longTxExecutionDelay) external {
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

  function test_ApproveActionsBuilderOrHub_WhenCallerIsSafe(
    uint256 _approvalDuration,
    address _actionsBuilder
  ) external {
    _approvalDuration = bound(_approvalDuration, 0, MAX_APPROVAL_DURATION);

    vm.expectEmit(address(canonGuard));
    emit ICanonGuard.ActionsBuilderOrHubApproved(
      _actionsBuilder, _approvalDuration, block.timestamp + _approvalDuration
    );

    vm.prank(SAFE);
    canonGuard.approveActionsBuilderOrHub(_actionsBuilder, _approvalDuration);

    assertEq(canonGuard.approvalExpiries(_actionsBuilder), block.timestamp + _approvalDuration);
  }

  function test_ApproveActionsBuilderOrHub_WhenApprovalDurationIsGreaterThanMaxApprovalDuration(uint256 _approvalDuration)
    external
    whenCallerIsSafe
  {
    _approvalDuration = bound(_approvalDuration, canonGuard.MAX_APPROVAL_DURATION() + 1, type(uint256).max);

    // it reverts with InvalidApprovalDuration
    vm.expectRevert(ICanonGuard.InvalidApprovalDuration.selector);
    canonGuard.approveActionsBuilderOrHub(address(0), _approvalDuration);
  }

  function test_ApproveActionsBuilderOrHub_WhenExtendingApproval(
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

  function test_ApproveActionsBuilderOrHub_WhenCallerIsNotSafe(
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

  modifier whenActionBuilderDoesNotDeclareAHub(address _actionsBuilder) {
    vm.mockCallRevert(_actionsBuilder, abi.encodeWithSelector(IActionHubChild.HUB.selector), 'Not implemented');
    _;
  }

  function test_QueueTransaction_WhenTransactionIsAlreadyQueuedButExpired(
    address _caller,
    address _target,
    uint256 _value,
    address _actionsBuilder,
    bytes memory _data
  ) external whenCallerIsSafeOwner whenActionBuilderDoesNotDeclareAHub(_actionsBuilder) {
    _assumeFuzzable(_actionsBuilder);
    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = IActionsBuilder.Action({target: _target, value: _value, data: _data});

    _mockAndExpect(
      address(_actionsBuilder), abi.encodeWithSelector(IActionsBuilder.getActions.selector), abi.encode(_actions)
    );

    vm.prank(_caller);
    canonGuard.queueTransaction(_actionsBuilder);

    // Move time forward past expiry
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY + TX_EXPIRY_DELAY + 1);

    vm.prank(_caller);
    canonGuard.queueTransaction(_actionsBuilder);

    // Verify transaction info using the new interface
    (,,, uint256 _expiresAt,) = canonGuard.transactionsInfo(_actionsBuilder);

    // it sets transaction info
    assertEq(_expiresAt, block.timestamp + LONG_TX_EXECUTION_DELAY + TX_EXPIRY_DELAY);

    // it does not re add the action builder to the queue
    assertEq(canonGuard.getQueuedActionBuilders().length, 1);
    assertEq(canonGuard.getQueuedActionBuilders()[0], _actionsBuilder);
  }

  function test_QueueTransaction_WhenTransactionIsAlreadyQueuedAndNotExpired(
    address _caller,
    address _actionsBuilder,
    uint256 _expiry
  ) external whenCallerIsSafeOwner whenActionBuilderDoesNotDeclareAHub(_actionsBuilder) {
    _assumeFuzzable(_actionsBuilder);
    _expiry = bound(_expiry, block.timestamp + 1, block.timestamp + TX_EXPIRY_DELAY);

    canonGuard.mockTransaction(
      _caller, _actionsBuilder, abi.encode(new IActionsBuilder.Action[](0)), block.timestamp, _expiry, false
    );

    // it reverts with TransactionAlreadyQueued
    vm.prank(_caller);
    vm.expectRevert(abi.encodeWithSelector(ICanonGuard.TransactionAlreadyQueued.selector, _actionsBuilder));
    canonGuard.queueTransaction(_actionsBuilder);
  }

  function test_QueueTransaction_WhenActionBuilderIsPreApproved(
    address _caller,
    address _actionsBuilder
  )
    external
    whenCallerIsSafeOwner
    whenActionBuilderDoesNotDeclareAHub(_actionsBuilder)
    givenActionsBuilderIsApproved(_actionsBuilder)
  {
    _mockAndExpect(
      address(_actionsBuilder),
      abi.encodeWithSelector(IActionsBuilder.getActions.selector),
      abi.encode(new IActionsBuilder.Action[](0))
    );

    // it emits TransactionQueued event
    vm.expectEmit(address(canonGuard));
    emit ICanonGuard.TransactionQueued(_caller, _actionsBuilder, address(0), true);

    vm.prank(_caller);
    canonGuard.queueTransaction(_actionsBuilder);

    // Verify transaction info using the new interface
    (address _proposer, bytes memory _actionsData, uint256 _executableAt, uint256 _expiresAt, bool _isPreApproved) =
      canonGuard.transactionsInfo(_actionsBuilder);

    // it sets the proposer
    assertEq(_proposer, _caller);
    // it sets transaction info
    assertEq(_actionsData, abi.encode(new IActionsBuilder.Action[](0)));
    // it adds the action builder to the queue
    assertEq(canonGuard.getQueuedActionBuilders().length, 1);
    assertEq(canonGuard.getQueuedActionBuilders()[0], _actionsBuilder);
    // it sets executable time at block timestamp plus short delay
    assertEq(_executableAt, block.timestamp + SHORT_TX_EXECUTION_DELAY);
    // it sets expiry time at executable time plus expiry delay
    assertEq(_expiresAt, block.timestamp + SHORT_TX_EXECUTION_DELAY + TX_EXPIRY_DELAY);
    // it sets isPreApproved to true
    assertEq(_isPreApproved, true);
  }

  function test_QueueTransaction_WhenActionBuilderIsNotPreApproved(
    address _caller,
    address _target,
    uint256 _value,
    address _actionsBuilder,
    bytes memory _data
  ) external whenCallerIsSafeOwner whenActionBuilderDoesNotDeclareAHub(_actionsBuilder) {
    _assumeFuzzable(_actionsBuilder);

    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = IActionsBuilder.Action({target: _target, value: _value, data: _data});

    _mockAndExpect(
      address(_actionsBuilder), abi.encodeWithSelector(IActionsBuilder.getActions.selector), abi.encode(_actions)
    );

    // it emits TransactionQueued event
    vm.expectEmit(address(canonGuard));
    emit ICanonGuard.TransactionQueued(_caller, _actionsBuilder, address(0), false);

    vm.prank(_caller);
    canonGuard.queueTransaction(_actionsBuilder);

    // Verify transaction info using the new interface
    (address _proposer, bytes memory _actionsData, uint256 _executableAt, uint256 _expiresAt, bool _isPreApproved) =
      canonGuard.transactionsInfo(_actionsBuilder);

    // it sets the proposer
    assertEq(_proposer, _caller);
    // it sets transaction info
    assertEq(_actionsData, abi.encode(_actions));
    // it adds the action builder to the queue
    assertEq(canonGuard.getQueuedActionBuilders().length, 1);
    assertEq(canonGuard.getQueuedActionBuilders()[0], _actionsBuilder);
    // it sets executable time at block timestamp plus long delay
    assertEq(_executableAt, block.timestamp + LONG_TX_EXECUTION_DELAY);
    // it sets expiry time at executable time plus expiry delay
    assertEq(_expiresAt, block.timestamp + LONG_TX_EXECUTION_DELAY + TX_EXPIRY_DELAY);
    // it sets isPreApproved to false
    assertEq(_isPreApproved, false);
  }

  modifier whenActionBuilderDeclaresAHub(address _actionsBuilder, address _actionHub) {
    _mockAndExpect(
      address(_actionsBuilder), abi.encodeWithSelector(IActionHubChild.HUB.selector), abi.encode(_actionHub)
    );
    _;
  }

  function test_QueueTransaction_WhenHubTransactionIsAlreadyQueuedButExpired(
    address _caller,
    address _actionHub,
    address _actionsBuilder,
    address _target,
    uint256 _value,
    bytes memory _data
  ) external whenCallerIsSafeOwner whenActionBuilderDeclaresAHub(_actionsBuilder, _actionHub) {
    _assumeFuzzable(_actionsBuilder);
    _assumeFuzzable(_actionHub);
    _assumeFuzzable(_caller);

    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = IActionsBuilder.Action({target: _target, value: _value, data: _data});

    _mockAndExpect(
      address(_actionsBuilder), abi.encodeWithSelector(IActionsBuilder.getActions.selector), abi.encode(_actions)
    );
    _mockAndExpect(address(_actionHub), abi.encodeWithSelector(IActionHub.isHubChild.selector), abi.encode(true));

    vm.prank(_caller);
    canonGuard.queueTransaction(_actionsBuilder);

    // Move time forward past expiry
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY + TX_EXPIRY_DELAY + 1);

    vm.prank(_caller);
    canonGuard.queueTransaction(_actionsBuilder);

    // Verify transaction info using the new interface
    (,,, uint256 _expiresAt,) = canonGuard.transactionsInfo(_actionsBuilder);

    // it should queue the transaction
    assertEq(_expiresAt, block.timestamp + LONG_TX_EXECUTION_DELAY + TX_EXPIRY_DELAY);

    // it does not re add the action builder to the queue
    assertEq(canonGuard.getQueuedActionBuilders().length, 1);
    assertEq(canonGuard.getQueuedActionBuilders()[0], _actionsBuilder);
  }

  function test_QueueTransaction_WhenHubTransactionIsAlreadyQueuedAndNotExpired(
    address _caller,
    address _actionHub,
    address _actionsBuilder,
    uint256 _expiry
  ) external whenCallerIsSafeOwner whenActionBuilderDeclaresAHub(_actionsBuilder, _actionHub) {
    _assumeFuzzable(_actionHub);
    _assumeFuzzable(_actionsBuilder);
    _assumeFuzzable(_caller);

    _expiry = bound(_expiry, block.timestamp + 1, block.timestamp + TX_EXPIRY_DELAY);

    _mockAndExpect(address(_actionHub), abi.encodeWithSelector(IActionHub.isHubChild.selector), abi.encode(true));

    canonGuard.mockTransaction(
      _caller, _actionsBuilder, abi.encode(new IActionsBuilder.Action[](0)), block.timestamp, _expiry, false
    );

    // it reverts with TransactionAlreadyQueued
    vm.expectRevert(abi.encodeWithSelector(ICanonGuard.TransactionAlreadyQueued.selector, _actionsBuilder));
    vm.prank(_caller);
    canonGuard.queueTransaction(_actionsBuilder);
  }

  function test_QueueTransaction_WhenActionBuilderIsNotAChildOfTheHub(
    address _caller,
    address _actionHub,
    address _actionsBuilder
  ) external whenCallerIsSafeOwner {
    _assumeFuzzable(_actionHub);
    _assumeFuzzable(_actionsBuilder);
    _assumeFuzzable(_caller);

    _mockAndExpect(
      address(_actionsBuilder), abi.encodeWithSelector(IActionHubChild.HUB.selector), abi.encode(_actionHub)
    );
    _mockAndExpect(address(_actionHub), abi.encodeWithSelector(IActionHub.isHubChild.selector), abi.encode(false));

    // it reverts with InvalidActionBuilderHubParent
    vm.prank(_caller);
    vm.expectRevert(ICanonGuard.InvalidActionBuilderHubParent.selector);
    canonGuard.queueTransaction(_actionsBuilder);
  }

  modifier whenActionBuilderIsAChildOfTheHub(address _actionHub, address _actionsBuilder) {
    vm.mockCall(_actionHub, abi.encodeWithSelector(IActionHub.isHubChild.selector, _actionsBuilder), abi.encode(true));
    _;
  }

  function test_QueueTransaction_WhenActionHubIsPreApproved(
    address _caller,
    address _actionHub,
    address _actionsBuilder
  )
    external
    whenCallerIsSafeOwner
    whenActionBuilderDeclaresAHub(_actionsBuilder, _actionHub)
    whenActionBuilderIsAChildOfTheHub(_actionHub, _actionsBuilder)
    givenActionsBuilderIsApproved(_actionHub)
  {
    _assumeFuzzable(_actionHub);
    _assumeFuzzable(_actionsBuilder);

    _mockAndExpect(
      address(_actionsBuilder),
      abi.encodeWithSelector(IActionsBuilder.getActions.selector),
      abi.encode(new IActionsBuilder.Action[](0))
    );

    // it emits TransactionQueued event
    vm.expectEmit(address(canonGuard));
    emit ICanonGuard.TransactionQueued(_caller, _actionsBuilder, _actionHub, true);

    vm.prank(_caller);
    canonGuard.queueTransaction(_actionsBuilder);

    // Verify transaction info using the new interface
    (address _proposer, bytes memory _actionsData, uint256 _executableAt, uint256 _expiresAt, bool _isPreApproved) =
      canonGuard.transactionsInfo(_actionsBuilder);

    // it sets the proposer
    assertEq(_proposer, _caller);
    // it sets transaction info
    assertEq(_actionsData, abi.encode(new IActionsBuilder.Action[](0)));
    // it adds the action builder to the queue
    assertEq(canonGuard.getQueuedActionBuilders().length, 1);
    assertEq(canonGuard.getQueuedActionBuilders()[0], _actionsBuilder);
    // it sets executable at to block timestamp plus short delay
    assertEq(_executableAt, block.timestamp + SHORT_TX_EXECUTION_DELAY);
    // it sets expiry time
    assertEq(_expiresAt, block.timestamp + SHORT_TX_EXECUTION_DELAY + TX_EXPIRY_DELAY);
    // it sets isPreApproved to true
    assertEq(_isPreApproved, true);
  }

  function test_QueueTransaction_WhenActionHubIsNotPreApproved(
    address _caller,
    address _target,
    uint256 _value,
    address _actionHub,
    address _actionsBuilder,
    bytes memory _data
  ) external whenCallerIsSafeOwner whenActionBuilderDeclaresAHub(_actionsBuilder, _actionHub) {
    _assumeFuzzable(_actionsBuilder);
    _assumeFuzzable(_actionHub);

    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = IActionsBuilder.Action({target: _target, value: _value, data: _data});

    _mockAndExpect(
      address(_actionsBuilder), abi.encodeWithSelector(IActionsBuilder.getActions.selector), abi.encode(_actions)
    );
    _mockAndExpect(address(_actionHub), abi.encodeWithSelector(IActionHub.isHubChild.selector), abi.encode(true));

    // it emits TransactionQueued event
    vm.expectEmit(address(canonGuard));
    emit ICanonGuard.TransactionQueued(_caller, _actionsBuilder, _actionHub, false);

    vm.prank(_caller);
    canonGuard.queueTransaction(_actionsBuilder);

    // Verify transaction info using the new interface
    (address _proposer, bytes memory _actionsData, uint256 _executableAt, uint256 _expiresAt, bool _isPreApproved) =
      canonGuard.transactionsInfo(_actionsBuilder);

    // it sets the proposer
    assertEq(_proposer, _caller);
    // it sets transaction info
    assertEq(_actionsData, abi.encode(_actions));
    // it adds the action builder to the queue
    assertEq(canonGuard.getQueuedActionBuilders().length, 1);
    assertEq(canonGuard.getQueuedActionBuilders()[0], _actionsBuilder);
    // it sets executable at to block timestamp plus long delay
    assertEq(_executableAt, block.timestamp + LONG_TX_EXECUTION_DELAY);
    // it sets expiry time
    assertEq(_expiresAt, block.timestamp + LONG_TX_EXECUTION_DELAY + TX_EXPIRY_DELAY);
    // it sets isPreApproved to false
    assertEq(_isPreApproved, false);
  }

  function test_QueueTransaction_WhenCallerIsNotSafeOwner(
    address _caller,
    address _actionsBuilder
  ) external givenCallerIsNotSafeOwner(_caller) {
    // it reverts with NotSafeOwner
    vm.expectRevert(ISafeManageable.NotSafeOwner.selector);
    vm.prank(_caller);
    canonGuard.queueTransaction(_actionsBuilder);
  }

  function test_ExecuteTransaction_WhenInEmergencyModeAndTheCallerIsNotTheEmergencyCaller(
    address _caller,
    address _actionsBuilder
  ) external whenEmergencyModeIsActive {
    vm.assume(_caller != EMERGENCY_CALLER);

    // it reverts with Unauthorized
    vm.prank(_caller);
    vm.expectRevert(abi.encodeWithSelector(IEmergencyModeHook.Unauthorized.selector, _caller, EMERGENCY_CALLER));
    canonGuard.executeTransaction(_actionsBuilder);
  }

  function test_ExecuteTransaction_WhenTransactionIsExpired(
    address _caller,
    address _actionsBuilder,
    IActionsBuilder.Action calldata _action,
    ICanonGuard.TransactionInfo memory _txInfo
  ) external {
    _assumeFuzzable(_actionsBuilder);
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

    canonGuard.mockTransaction(
      _txInfo.proposer, _actionsBuilder, _actionsData, _txInfo.executableAt, _txInfo.expiresAt, _txInfo.isPreApproved
    );

    // Move time forward past expiry
    vm.warp(_txInfo.expiresAt + 1);

    vm.expectRevert(ICanonGuard.TransactionExpired.selector);
    vm.prank(_caller);
    canonGuard.executeTransaction(_actionsBuilder);
  }

  function test_ExecuteTransaction_WhenApprovedTransactionIsNotYetExecutable(
    address _caller,
    address _actionsBuilder,
    IActionsBuilder.Action calldata _action,
    ICanonGuard.TransactionInfo memory _txInfo
  ) external {
    _assumeFuzzable(_actionsBuilder);
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
      _txInfo.proposer, // proposer
      _actionsBuilder, // actionsBuilder
      _actionsData, // actionsData
      _txInfo.executableAt, // executableAt
      _txInfo.expiresAt, // expiresAt
      _txInfo.isPreApproved // isPrePreApproved
    );

    vm.expectRevert(ICanonGuard.TransactionNotYetExecutable.selector);
    vm.prank(_caller);
    canonGuard.executeTransaction(_actionsBuilder);
  }

  function test_ExecuteTransaction_WhenTransactionIsNotQueued(address _actionsBuilder) external {
    _assumeFuzzable(_actionsBuilder);
    _mockAndExpect(address(SAFE), abi.encodeWithSelector(ISafe.nonce.selector), abi.encode(1));

    // it reverts with TransactionNotQueued
    vm.expectRevert(ICanonGuard.NoTransactionQueued.selector);
    canonGuard.executeTransaction(_actionsBuilder);
  }

  modifier whenApprovedTransactionIsValid() {
    _;
  }

  function test_ExecuteTransaction_WhenInSimulationMode(
    address _caller,
    address _actionsBuilder,
    IActionsBuilder.Action calldata _action,
    ICanonGuard.TransactionInfo memory _txInfo
  ) external whenApprovedTransactionIsValid {
    _assumeFuzzable(_actionsBuilder);
    vm.store(address(canonGuard), bytes32(uint256(4)), bytes32(uint256(1))); // sets _isSimulation to true
    _txInfo.expiresAt = bound(_txInfo.expiresAt, block.timestamp + 1, type(uint256).max);
    _txInfo.executableAt = bound(_txInfo.executableAt, block.timestamp - 1, block.timestamp);

    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = _action;
    bytes memory _actionsData = abi.encode(_actions);

    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.nonce.selector), abi.encode(1));
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.getTransactionHash.selector), abi.encode(bytes32(0)));

    // it executes transaction with CanonGuard as signer
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.execTransaction.selector), abi.encode(true));

    canonGuard.mockTransaction(
      _txInfo.proposer, // proposer
      _actionsBuilder, // actionsBuilder
      _actionsData, // actionsData
      _txInfo.executableAt, // executableAt
      _txInfo.expiresAt, // expiresAt
      _txInfo.isPreApproved // isPreApproved
    );

    address[] memory _signers = new address[](1);
    _signers[0] = address(canonGuard);

    // it emits TransactionExecuted event
    vm.expectEmit(address(canonGuard));
    emit ICanonGuard.TransactionExecuted(_actionsBuilder, bytes32(0), _signers, _txInfo.isPreApproved);

    vm.prank(_caller);
    canonGuard.executeTransaction(_actionsBuilder);

    // it deletes transaction from mapping
    (address _proposer, bytes memory __actionsData, uint256 _executableAt, uint256 _expiresAt, bool _isPreApproved) =
      canonGuard.transactionsInfo(_actionsBuilder);
    assertEq(__actionsData, bytes(''));
    assertEq(_executableAt, 0);
    assertEq(_proposer, address(0));
    assertEq(_expiresAt, 0);
    assertEq(_isPreApproved, false);

    // it deletes transaction from queue
    assertEq(canonGuard.getQueuedActionBuilders().length, 0);
  }

  function test_ExecuteTransaction_WhenNotInSimulationMode(
    address _caller,
    address _actionsBuilder,
    IActionsBuilder.Action calldata _action,
    ICanonGuard.TransactionInfo memory _txInfo,
    address _signer1,
    address _signer2
  ) external whenApprovedTransactionIsValid {
    _assumeFuzzable(_actionsBuilder);
    vm.assume(_signer1 > _signer2);
    vm.assume(_signer2 != address(0));
    _txInfo.expiresAt = bound(_txInfo.expiresAt, block.timestamp + 1, type(uint256).max);
    _txInfo.executableAt = bound(_txInfo.executableAt, block.timestamp - 1, block.timestamp);
    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = _action;
    bytes memory _actionsData = abi.encode(_actions);

    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.nonce.selector), abi.encode(1));
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.getTransactionHash.selector), abi.encode(bytes32(0)));
    address[] memory _signers = new address[](2);
    _signers[0] = _signer1;
    _signers[1] = _signer2;
    _mockAndExpect(SAFE, abi.encodeWithSelector(IOwnerManager.getOwners.selector), abi.encode(_signers));
    _mockApprovedHashesForSigners(_signers, 1);

    // it executes transaction
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.execTransaction.selector), abi.encode(true));

    canonGuard.mockTransaction(
      _txInfo.proposer, // proposer
      _actionsBuilder, // actionsBuilder
      _actionsData, // actionsData
      _txInfo.executableAt, // executableAt
      _txInfo.expiresAt, // expiresAt
      _txInfo.isPreApproved // isPreApproved
    );

    address[] memory _sortedSigners = new address[](2);
    _sortedSigners[0] = _signer2;
    _sortedSigners[1] = _signer1;

    // it emits TransactionExecuted event
    vm.expectEmit(address(canonGuard));
    emit ICanonGuard.TransactionExecuted(_actionsBuilder, bytes32(0), _sortedSigners, _txInfo.isPreApproved);

    vm.prank(_caller);
    canonGuard.executeTransaction(_actionsBuilder);

    // it deletes transaction from mapping
    (address _proposer, bytes memory __actionsData, uint256 _executableAt, uint256 _expiresAt, bool _isPreApproved) =
      canonGuard.transactionsInfo(_actionsBuilder);
    assertEq(__actionsData, bytes(''));
    assertEq(_executableAt, 0);
    assertEq(_proposer, address(0));
    assertEq(_expiresAt, 0);
    assertEq(_isPreApproved, false);

    // it deletes transaction from queue
    assertEq(canonGuard.getQueuedActionBuilders().length, 0);
  }

  function test_ExecuteTransactions_WhenInEmergencyModeAndTheCallerIsNotTheEmergencyCaller(
    address _caller,
    address[] memory _actionsBuilders
  ) external whenEmergencyModeIsActive {
    vm.assume(_caller != EMERGENCY_CALLER);

    // it reverts with Unauthorized
    vm.prank(_caller);
    vm.expectRevert(abi.encodeWithSelector(IEmergencyModeHook.Unauthorized.selector, _caller, EMERGENCY_CALLER));
    canonGuard.executeTransactions(_actionsBuilders);
  }

  function test_ExecuteTransactions_WhenAtLeastOneTransactionIsExpired(
    address _caller,
    IActionsBuilder.Action calldata _action,
    ICanonGuard.TransactionInfo[] memory _txsInfo
  ) external {
    vm.assume(_txsInfo.length > 2);
    _txsInfo[0].expiresAt = bound(_txsInfo[0].expiresAt, 5, type(uint64).max);
    _txsInfo[0].executableAt = bound(_txsInfo[0].executableAt, 0, block.timestamp);
    _txsInfo[1].expiresAt = bound(_txsInfo[1].expiresAt, 1, _txsInfo[0].expiresAt - 2);
    _txsInfo[1].executableAt = bound(_txsInfo[1].executableAt, 0, block.timestamp);
    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = _action;
    bytes memory _actionsData = abi.encode(_actions);
    address[] memory _actionsBuilders = new address[](_txsInfo.length);

    // Mock SAFE contract calls
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.nonce.selector), abi.encode(1));
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.getTransactionHash.selector), abi.encode(bytes32(0)));
    _mockAndExpect(SAFE, abi.encodeWithSelector(IOwnerManager.getOwners.selector), abi.encode(new address[](0)));

    // tx 0 executes
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.execTransaction.selector), abi.encode(true));
    for (uint256 _i; _i < _actionsBuilders.length; ++_i) {
      _actionsBuilders[_i] = makeAddr(string(abi.encodePacked(_i)));
      canonGuard.mockTransaction(
        _txsInfo[_i].proposer,
        _actionsBuilders[_i],
        _actionsData,
        _txsInfo[_i].executableAt,
        _txsInfo[_i].expiresAt,
        _txsInfo[_i].isPreApproved
      );
    }

    // Move time forward to expire tx with index 1
    vm.warp(_txsInfo[1].expiresAt + 1);

    // it reverts with TransactionExpired
    vm.expectRevert(ICanonGuard.TransactionExpired.selector);
    vm.prank(_caller);
    canonGuard.executeTransactions(_actionsBuilders);
  }

  function test_ExecuteTransactions_WhenAtLeastOneApprovedTransactionIsNotYetExecutable(
    address _caller,
    IActionsBuilder.Action calldata _action,
    ICanonGuard.TransactionInfo[] memory _txsInfo
  ) external {
    vm.assume(_txsInfo.length > 2);
    _txsInfo[0].expiresAt = bound(_txsInfo[0].expiresAt, block.timestamp + 1, type(uint256).max);
    _txsInfo[0].executableAt = bound(_txsInfo[0].executableAt, 0, block.timestamp);

    // tx with index 1 is not yet executable
    _txsInfo[1].expiresAt = bound(_txsInfo[1].expiresAt, block.timestamp + 1, type(uint256).max);
    _txsInfo[1].executableAt = bound(_txsInfo[1].executableAt, block.timestamp + 1, type(uint256).max);
    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = _action;
    bytes memory _actionsData = abi.encode(_actions);
    address[] memory _actionsBuilders = new address[](_txsInfo.length);

    // Mock SAFE contract calls
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.nonce.selector), abi.encode(1));
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.getTransactionHash.selector), abi.encode(bytes32(0)));
    _mockAndExpect(SAFE, abi.encodeWithSelector(IOwnerManager.getOwners.selector), abi.encode(new address[](0)));

    // tx 0 executes
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.execTransaction.selector), abi.encode(true));
    for (uint256 _i; _i < _actionsBuilders.length; ++_i) {
      _actionsBuilders[_i] = makeAddr(string(abi.encodePacked(_i)));
      canonGuard.mockTransaction(
        _txsInfo[_i].proposer,
        _actionsBuilders[_i],
        _actionsData,
        _txsInfo[_i].executableAt,
        _txsInfo[_i].expiresAt,
        _txsInfo[_i].isPreApproved
      );
    }

    // it reverts with TransactionNotYetExecutable
    vm.expectRevert(ICanonGuard.TransactionNotYetExecutable.selector);
    vm.prank(_caller);
    canonGuard.executeTransactions(_actionsBuilders);
  }

  function test_ExecuteTransactions_WhenAtLeastOneTransactionIsNotQueued(
    address _caller,
    IActionsBuilder.Action calldata _action,
    ICanonGuard.TransactionInfo[] memory _txsInfo
  ) external {
    vm.assume(_txsInfo.length > 2);
    _txsInfo[0].expiresAt = bound(_txsInfo[0].expiresAt, block.timestamp + 1, type(uint256).max);
    _txsInfo[0].executableAt = bound(_txsInfo[0].executableAt, 0, block.timestamp);

    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = _action;
    bytes memory _actionsData = abi.encode(_actions);
    address[] memory _actionsBuilders = new address[](_txsInfo.length);

    // Mock SAFE contract calls
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.nonce.selector), abi.encode(1));
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.getTransactionHash.selector), abi.encode(bytes32(0)));
    _mockAndExpect(SAFE, abi.encodeWithSelector(IOwnerManager.getOwners.selector), abi.encode(new address[](0)));

    // tx 0 executes
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.execTransaction.selector), abi.encode(true));
    for (uint256 _i; _i < _actionsBuilders.length; ++_i) {
      // Don't add tx 1 to the queue
      if (_i != 1) {
        _actionsBuilders[_i] = makeAddr(string(abi.encodePacked(_i)));
        canonGuard.mockTransaction(
          _txsInfo[_i].proposer,
          _actionsBuilders[_i],
          _actionsData,
          _txsInfo[_i].executableAt,
          _txsInfo[_i].expiresAt,
          _txsInfo[_i].isPreApproved
        );
      }
    }

    // it reverts with NoTransactionQueued
    vm.expectRevert(ICanonGuard.NoTransactionQueued.selector);
    vm.prank(_caller);
    canonGuard.executeTransactions(_actionsBuilders);
  }

  modifier whenAllTransactionsAreValid() {
    _;
  }

  function test_ExecuteTransactions_WhenInSimulationMode(
    address _caller,
    IActionsBuilder.Action calldata _action,
    ICanonGuard.TransactionInfo[] memory _txsInfo
  ) external whenAllTransactionsAreValid {
    vm.assume(_txsInfo.length > 1);
    vm.store(address(canonGuard), bytes32(uint256(4)), bytes32(uint256(1))); // sets _isSimulation to true

    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = _action;
    bytes memory _actionsData = abi.encode(_actions);
    address[] memory _actionsBuilders = new address[](_txsInfo.length);

    // Mock SAFE contract calls
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.nonce.selector), abi.encode(1));
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.getTransactionHash.selector), abi.encode(bytes32(0)));
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.execTransaction.selector), abi.encode(true));

    for (uint256 _i; _i < _actionsBuilders.length; ++_i) {
      _txsInfo[_i].expiresAt = bound(_txsInfo[_i].expiresAt, block.timestamp + 1, type(uint256).max);
      _txsInfo[_i].executableAt = bound(_txsInfo[_i].executableAt, 0, block.timestamp);
      _actionsBuilders[_i] = makeAddr(string(abi.encodePacked(_i)));
      canonGuard.mockTransaction(
        _txsInfo[_i].proposer,
        _actionsBuilders[_i],
        _actionsData,
        _txsInfo[_i].executableAt,
        _txsInfo[_i].expiresAt,
        _txsInfo[_i].isPreApproved
      );
    }

    address[] memory _signers = new address[](1);
    _signers[0] = address(canonGuard);

    // it emits TransactionExecuted event
    for (uint256 _i; _i < _actionsBuilders.length; ++_i) {
      vm.expectEmit(address(canonGuard));
      emit ICanonGuard.TransactionExecuted(_actionsBuilders[_i], bytes32(0), _signers, _txsInfo[_i].isPreApproved);
    }

    // it executes transactions with CanonGuard as signer
    vm.prank(_caller);
    canonGuard.executeTransactions(_actionsBuilders);

    for (uint256 _i; _i < _actionsBuilders.length; ++_i) {
      // it deletes transactions from mapping
      (address _proposer, bytes memory __actionsData, uint256 _executableAt, uint256 _expiresAt, bool _isPreApproved) =
        canonGuard.transactionsInfo(_actionsBuilders[_i]);
      assertEq(__actionsData, bytes(''));
      assertEq(_executableAt, 0);
      assertEq(_proposer, address(0));
      assertEq(_expiresAt, 0);
      assertEq(_isPreApproved, false);
    }
    // it deletes transactions from queue
    assertEq(canonGuard.getQueuedActionBuilders().length, 0);
  }

  function test_ExecuteTransactions_WhenNotInSimulationMode(
    address _caller,
    IActionsBuilder.Action calldata _action,
    ICanonGuard.TransactionInfo[] memory _txsInfo,
    address _signer1,
    address _signer2
  ) external whenAllTransactionsAreValid {
    vm.assume(_signer1 > _signer2);
    vm.assume(_signer2 != address(0));
    vm.assume(_txsInfo.length > 1);

    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = _action;
    bytes memory _actionsData = abi.encode(_actions);
    address[] memory _actionsBuilders = new address[](_txsInfo.length);

    // Mock SAFE contract calls
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.nonce.selector), abi.encode(1));
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.getTransactionHash.selector), abi.encode(bytes32(0)));
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.execTransaction.selector), abi.encode(true));

    address[] memory _signers = new address[](2);
    _signers[0] = _signer1;
    _signers[1] = _signer2;
    _mockAndExpect(SAFE, abi.encodeWithSelector(IOwnerManager.getOwners.selector), abi.encode(_signers));
    _mockApprovedHashesForSigners(_signers, 1);

    for (uint256 _i; _i < _actionsBuilders.length; ++_i) {
      _txsInfo[_i].expiresAt = bound(_txsInfo[_i].expiresAt, block.timestamp + 1, type(uint256).max);
      _txsInfo[_i].executableAt = bound(_txsInfo[_i].executableAt, 0, block.timestamp);
      _actionsBuilders[_i] = makeAddr(string(abi.encodePacked(_i)));
      canonGuard.mockTransaction(
        _txsInfo[_i].proposer,
        _actionsBuilders[_i],
        _actionsData,
        _txsInfo[_i].executableAt,
        _txsInfo[_i].expiresAt,
        _txsInfo[_i].isPreApproved
      );
    }

    address[] memory _sortedSigners = new address[](2);
    _sortedSigners[0] = _signer2;
    _sortedSigners[1] = _signer1;

    // it emits TransactionExecuted event
    for (uint256 _i; _i < _actionsBuilders.length; ++_i) {
      vm.expectEmit(address(canonGuard));
      emit ICanonGuard.TransactionExecuted(_actionsBuilders[_i], bytes32(0), _sortedSigners, _txsInfo[_i].isPreApproved);
    }

    // it executes transactions with CanonGuard as signer
    vm.prank(_caller);
    canonGuard.executeTransactions(_actionsBuilders);

    for (uint256 _i; _i < _actionsBuilders.length; ++_i) {
      // it deletes transactions from mapping
      (address _proposer, bytes memory __actionsData, uint256 _executableAt, uint256 _expiresAt, bool _isPreApproved) =
        canonGuard.transactionsInfo(_actionsBuilders[_i]);
      assertEq(__actionsData, bytes(''));
      assertEq(_executableAt, 0);
      assertEq(_proposer, address(0));
      assertEq(_expiresAt, 0);
      assertEq(_isPreApproved, false);
    }
    // it deletes transactions from queue
    assertEq(canonGuard.getQueuedActionBuilders().length, 0);
  }

  modifier whenEmergencyModeIsActive() {
    vm.prank(canonGuard.emergencyTrigger());
    canonGuard.setEmergencyMode();
    _;
  }

  function test_CancelEnqueuedTransaction_WhenTheCallerIsNotTheEmergencyCaller(
    address _caller,
    address _actionsBuilder
  ) external whenEmergencyModeIsActive {
    vm.assume(_caller != EMERGENCY_CALLER);

    // it reverts with Unauthorized
    vm.prank(_caller);
    vm.expectRevert(abi.encodeWithSelector(IEmergencyModeHook.Unauthorized.selector, _caller, EMERGENCY_CALLER));
    canonGuard.cancelEnqueuedTransaction(_actionsBuilder);
  }

  function test_CancelEnqueuedTransaction_WhenTheCallerIsTheEmergencyCallerAndProposer(
    address _actionsBuilder,
    IActionsBuilder.Action calldata _action,
    ICanonGuard.TransactionInfo memory _txInfo
  ) external whenEmergencyModeIsActive {
    _assumeFuzzable(_actionsBuilder);
    _txInfo.expiresAt = bound(_txInfo.expiresAt, 1, type(uint64).max - 1);
    _txInfo.proposer = EMERGENCY_CALLER;

    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = _action;
    bytes memory _actionsData = abi.encode(_actions);

    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.nonce.selector), abi.encode(1));
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.getTransactionHash.selector), abi.encode(bytes32(0)));
    _mockAndExpect(SAFE, abi.encodeWithSelector(IOwnerManager.getOwners.selector), abi.encode(new address[](0)));

    canonGuard.mockTransaction(
      _txInfo.proposer, _actionsBuilder, _actionsData, _txInfo.executableAt, _txInfo.expiresAt, _txInfo.isPreApproved
    );

    // it emits EnqueuedTransactionCancelled event
    vm.prank(EMERGENCY_CALLER);
    vm.expectEmit(address(canonGuard));
    emit ICanonGuard.EnqueuedTransactionCancelled(_actionsBuilder, EMERGENCY_CALLER, bytes32(0));
    canonGuard.cancelEnqueuedTransaction(_actionsBuilder);

    // it deletes transaction from queue
    (address _proposer, bytes memory __actionsData, uint256 _executableAt, uint256 _expiresAt, bool _isPreApproved) =
      canonGuard.transactionsInfo(_actionsBuilder);
    assertEq(__actionsData, bytes(''));
    assertEq(_executableAt, 0);
    assertEq(_proposer, address(0));
    assertEq(_expiresAt, 0);
    assertEq(_isPreApproved, false);

    // it deletes transaction from mapping
    assertEq(canonGuard.getQueuedActionBuilders().length, 0);
  }

  function test_CancelEnqueuedTransaction_WhenTheCallerIsTheEmergencyCallerAndNotTheProposer(
    address _actionsBuilder,
    IActionsBuilder.Action calldata _action,
    ICanonGuard.TransactionInfo memory _txInfo
  ) external whenEmergencyModeIsActive {
    _assumeFuzzable(_actionsBuilder);
    vm.assume(_txInfo.proposer != EMERGENCY_CALLER);
    _txInfo.expiresAt = bound(_txInfo.expiresAt, 1, type(uint64).max - 1);

    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = _action;
    bytes memory _actionsData = abi.encode(_actions);

    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.nonce.selector), abi.encode(1));
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.getTransactionHash.selector), abi.encode(bytes32(0)));
    _mockAndExpect(SAFE, abi.encodeWithSelector(IOwnerManager.getOwners.selector), abi.encode(new address[](0)));

    canonGuard.mockTransaction(
      _txInfo.proposer, _actionsBuilder, _actionsData, _txInfo.executableAt, _txInfo.expiresAt, _txInfo.isPreApproved
    );

    // it emits EnqueuedTransactionCancelled event
    vm.prank(EMERGENCY_CALLER);
    vm.expectEmit(address(canonGuard));
    emit ICanonGuard.EnqueuedTransactionCancelled(_actionsBuilder, EMERGENCY_CALLER, bytes32(0));
    canonGuard.cancelEnqueuedTransaction(_actionsBuilder);

    // it deletes transaction from queue
    (address _proposer, bytes memory __actionsData, uint256 _executableAt, uint256 _expiresAt, bool _isPreApproved) =
      canonGuard.transactionsInfo(_actionsBuilder);
    assertEq(__actionsData, bytes(''));
    assertEq(_executableAt, 0);
    assertEq(_proposer, address(0));
    assertEq(_expiresAt, 0);
    assertEq(_isPreApproved, false);

    // it deletes transaction from mapping
    assertEq(canonGuard.getQueuedActionBuilders().length, 0);
  }

  function test_CancelEnqueuedTransaction_WhenTransactionIsNotQueued(address _actionsBuilder) external {
    // it reverts with NoTransactionQueued
    vm.expectRevert(ICanonGuard.NoTransactionQueued.selector);
    canonGuard.cancelEnqueuedTransaction(_actionsBuilder);
  }

  function test_CancelEnqueuedTransaction_WhenCallerIsNotTheProposer(
    address _caller,
    address _actionsBuilder,
    IActionsBuilder.Action calldata _action,
    ICanonGuard.TransactionInfo memory _txInfo
  ) external {
    _assumeFuzzable(_actionsBuilder);
    vm.assume(_caller != _txInfo.proposer);
    _txInfo.expiresAt = bound(_txInfo.expiresAt, 1, type(uint64).max - 1);

    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = _action;
    bytes memory _actionsData = abi.encode(_actions);

    canonGuard.mockTransaction(
      _txInfo.proposer, _actionsBuilder, _actionsData, _txInfo.executableAt, _txInfo.expiresAt, _txInfo.isPreApproved
    );

    // it reverts with CallerMustBeTransactionProposer
    vm.prank(_caller);
    vm.expectRevert(ICanonGuard.CallerMustBeTransactionProposer.selector);
    canonGuard.cancelEnqueuedTransaction(_actionsBuilder);
  }

  function test_CancelEnqueuedTransaction_WhenTransactionHasApprovedHashSigners(
    address _actionsBuilder,
    IActionsBuilder.Action calldata _action,
    ICanonGuard.TransactionInfo memory _txInfo,
    address[] memory _signers
  ) external {
    _assumeFuzzable(_actionsBuilder);
    vm.assume(_signers.length > 0);
    _txInfo.expiresAt = bound(_txInfo.expiresAt, 1, type(uint64).max - 1);

    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = _action;
    bytes memory _actionsData = abi.encode(_actions);

    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.nonce.selector), abi.encode(1));
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.getTransactionHash.selector), abi.encode(bytes32(0)));
    _mockAndExpect(SAFE, abi.encodeWithSelector(IOwnerManager.getOwners.selector), abi.encode(_signers));
    _mockApprovedHashesForSigners(_signers, 1);

    canonGuard.mockTransaction(
      _txInfo.proposer, _actionsBuilder, _actionsData, _txInfo.executableAt, _txInfo.expiresAt, _txInfo.isPreApproved
    );

    // it reverts with TransactionWithSignaturesCannotBeCancelled
    vm.prank(_txInfo.proposer);
    vm.expectRevert(ICanonGuard.TransactionWithSignaturesCannotBeCancelled.selector);
    canonGuard.cancelEnqueuedTransaction(_actionsBuilder);
  }

  function test_CancelEnqueuedTransaction_WhenTransactionCanBeCancelled(
    address _actionsBuilder,
    IActionsBuilder.Action calldata _action,
    ICanonGuard.TransactionInfo memory _txInfo
  ) external {
    _assumeFuzzable(_actionsBuilder);
    _txInfo.expiresAt = bound(_txInfo.expiresAt, 1, type(uint64).max - 1);

    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = _action;
    bytes memory _actionsData = abi.encode(_actions);

    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.nonce.selector), abi.encode(1));
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.getTransactionHash.selector), abi.encode(bytes32(0)));
    _mockAndExpect(SAFE, abi.encodeWithSelector(IOwnerManager.getOwners.selector), abi.encode(new address[](0)));

    canonGuard.mockTransaction(
      _txInfo.proposer, _actionsBuilder, _actionsData, _txInfo.executableAt, _txInfo.expiresAt, _txInfo.isPreApproved
    );

    // it emits EnqueuedTransactionCancelled event
    vm.prank(_txInfo.proposer);
    vm.expectEmit(address(canonGuard));
    emit ICanonGuard.EnqueuedTransactionCancelled(_actionsBuilder, _txInfo.proposer, bytes32(0));
    canonGuard.cancelEnqueuedTransaction(_actionsBuilder);

    // it deletes transaction from queue
    (address _proposer, bytes memory __actionsData, uint256 _executableAt, uint256 _expiresAt, bool _isPreApproved) =
      canonGuard.transactionsInfo(_actionsBuilder);
    assertEq(__actionsData, bytes(''));
    assertEq(_executableAt, 0);
    assertEq(_proposer, address(0));
    assertEq(_expiresAt, 0);
    assertEq(_isPreApproved, false);

    // it deletes transaction from mapping
    assertEq(canonGuard.getQueuedActionBuilders().length, 0);
  }

  function test_ExecuteNoActionTransaction_WhenTheCallerIsTheEmergencyCaller(bytes32 _safeTxHash)
    external
    whenEmergencyModeIsActive
  {
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.nonce.selector), abi.encode(1));
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.getTransactionHash.selector), abi.encode(_safeTxHash));
    _mockAndExpect(SAFE, abi.encodeWithSelector(IOwnerManager.getOwners.selector), abi.encode(new address[](0)));

    // it executes transaction
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.execTransaction.selector), abi.encode(true));

    // it emits NoActionTransactionExecuted event
    vm.expectEmit();
    emit ICanonGuard.NoActionTransactionExecuted(_safeTxHash, new address[](0));

    vm.prank(canonGuard.emergencyCaller());
    canonGuard.executeNoActionTransaction();
  }

  function test_ExecuteNoActionTransaction_WhenTheCallerIsNotTheEmergencyCaller(address _caller)
    external
    whenEmergencyModeIsActive
  {
    vm.assume(_caller != EMERGENCY_CALLER);

    // it reverts with Unauthorized
    vm.prank(_caller);
    vm.expectRevert(abi.encodeWithSelector(IEmergencyModeHook.Unauthorized.selector, _caller, EMERGENCY_CALLER));
    canonGuard.executeNoActionTransaction();
  }

  function test_ExecuteNoActionTransaction_WhenEmergencyModeIsNotActive(bytes32 _safeTxHash) external {
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.nonce.selector), abi.encode(1));
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.getTransactionHash.selector), abi.encode(_safeTxHash));
    _mockAndExpect(SAFE, abi.encodeWithSelector(IOwnerManager.getOwners.selector), abi.encode(new address[](0)));

    // it executes transaction
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.execTransaction.selector), abi.encode(true));

    // it emits NoActionTransactionExecuted event
    vm.expectEmit();
    emit ICanonGuard.NoActionTransactionExecuted(_safeTxHash, new address[](0));

    canonGuard.executeNoActionTransaction();
  }

  function test_GetSafeTransactionHash_WhenTheAddressIsTheZeroAddress(
    uint256 _safeNonce,
    bytes32 _expectedHash
  ) external {
    // it returns correct hash
    _mockAndExpect(
      SAFE,
      abi.encodeWithSelector(
        ISafe.getTransactionHash.selector,
        canonGuard.MULTI_SEND_CALL_ONLY(),
        0,
        abi.encodeWithSelector(MultiSendCallOnly.multiSend.selector, bytes('')),
        Enum.Operation.DelegateCall,
        0,
        0,
        0,
        address(0),
        address(0),
        _safeNonce
      ),
      abi.encode(_expectedHash)
    );

    // it returns correct hash
    bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(address(0), _safeNonce);
    assertEq(_safeTxHash, _expectedHash);
  }

  modifier whenTheAddressIsNotTheZeroAddress(address _actionsBuilder) {
    _;
  }

  modifier whenTransactionExists() {
    _;
  }

  function test_GetSafeTransactionHash_WhenTransactionExists(
    address _actionsBuilder,
    IActionsBuilder.Action memory _action,
    ICanonGuard.TransactionInfo memory _txInfo,
    uint256 _safeNonce,
    bytes32 _expectedHash
  ) external whenTransactionExists {
    _assumeFuzzable(_actionsBuilder);
    // Ensure expiresAt is not 0 to avoid NoTransactionQueued error
    _txInfo.expiresAt = bound(_txInfo.expiresAt, 1, type(uint256).max);

    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = _action;
    bytes memory _actionsData = abi.encode(_actions);
    canonGuard.mockTransaction(
      _txInfo.proposer, _actionsBuilder, _actionsData, _txInfo.executableAt, _txInfo.expiresAt, _txInfo.isPreApproved
    );

    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.nonce.selector), abi.encode(_safeNonce));
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.getTransactionHash.selector), abi.encode(_expectedHash));

    bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(_actionsBuilder);
    assertEq(_safeTxHash, _expectedHash);
  }

  function test_GetSafeTransactionHash_WhenGettingHashWithNonce(
    address _actionsBuilder,
    IActionsBuilder.Action memory _action,
    ICanonGuard.TransactionInfo memory _txInfo,
    uint256 _safeNonce,
    bytes32 _expectedHash
  ) external whenTransactionExists {
    _assumeFuzzable(_actionsBuilder);
    // Ensure expiresAt is not 0 to avoid NoTransactionQueued error
    _txInfo.expiresAt = bound(_txInfo.expiresAt, 1, type(uint256).max);

    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = _action;
    bytes memory _actionsData = abi.encode(_actions);
    canonGuard.mockTransaction(
      _txInfo.proposer, _actionsBuilder, _actionsData, _txInfo.executableAt, _txInfo.expiresAt, _txInfo.isPreApproved
    );

    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.getTransactionHash.selector), abi.encode(_expectedHash));

    bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(_actionsBuilder, _safeNonce);
    assertEq(_safeTxHash, _expectedHash);
  }

  function test_GetSafeTransactionHash_WhenTransactionDoesNotExist(address _actionsBuilder) external {
    _assumeFuzzable(_actionsBuilder);

    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.nonce.selector), abi.encode(1));

    // it reverts with NoTransactionQueued
    vm.expectRevert(ICanonGuard.NoTransactionQueued.selector);
    canonGuard.getSafeTransactionHash(_actionsBuilder);
  }

  function test_GetApprovedHashSigners_WhenTheAddressIsTheZeroAddress(
    address _signer1,
    address _signer2,
    uint256 _safeNonce
  ) external {
    address[] memory _signers = new address[](2);
    _signers[0] = _signer1;
    _signers[1] = _signer2;
    _mockApprovedHashesForSigners(_signers, 1);

    _mockAndExpect(SAFE, abi.encodeWithSelector(IOwnerManager.getOwners.selector), abi.encode(_signers));
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.getTransactionHash.selector), abi.encode(bytes32(0)));

    // it returns approved signers for empty transaction
    address[] memory _approvedSigners = canonGuard.getApprovedHashSigners(address(0), _safeNonce);
    assertEq(_approvedSigners, _signers);
  }

  function test_GetApprovedHashSigners_WhenTransactionExists(
    address _signer1,
    address _signer2,
    address _actionsBuilder,
    IActionsBuilder.Action memory _action,
    ICanonGuard.TransactionInfo memory _txInfo,
    uint256 _safeNonce
  ) external {
    _assumeFuzzable(_actionsBuilder);
    // Ensure expiresAt is not 0 to avoid NoTransactionQueued error
    _txInfo.expiresAt = bound(_txInfo.expiresAt, 1, type(uint256).max);

    IActionsBuilder.Action[] memory _actions = new IActionsBuilder.Action[](1);
    _actions[0] = _action;
    bytes memory _actionsData = abi.encode(_actions);
    canonGuard.mockTransaction(
      _txInfo.proposer, _actionsBuilder, _actionsData, _txInfo.executableAt, _txInfo.expiresAt, _txInfo.isPreApproved
    );

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

  function test_GetApprovedHashSigners_WhenTransactionDoesNotExist(address _actionsBuilder, uint256 _nonce) external {
    _assumeFuzzable(_actionsBuilder);

    // it reverts with NoTransactionQueued
    vm.expectRevert(ICanonGuard.NoTransactionQueued.selector);
    canonGuard.getApprovedHashSigners(_actionsBuilder, _nonce);
  }

  function test_GetSafeNonce_ReturnsCorrectNonce(uint256 _nonce) external {
    _mockAndExpect(SAFE, abi.encodeWithSelector(ISafe.nonce.selector), abi.encode(_nonce));

    assertEq(canonGuard.getSafeNonce(), _nonce);
  }

  function test_GetQueuedActionBuilders_WhenThereAreActionBuildersInTheQueue(
    address _actionsBuilder,
    address _caller,
    IActionsBuilder.Action[] memory _actions,
    ICanonGuard.TransactionInfo memory _txInfo
  ) external {
    _assumeFuzzable(_actionsBuilder);
    _txInfo.expiresAt = bound(_txInfo.expiresAt, 1, type(uint256).max);

    canonGuard.mockTransaction(
      _caller, _actionsBuilder, abi.encode(_actions), _txInfo.executableAt, _txInfo.expiresAt, _txInfo.isPreApproved
    );

    // it returns the action builders in the queue
    assertEq(canonGuard.getQueuedActionBuilders().length, 1);
    assertEq(canonGuard.getQueuedActionBuilders()[0], _actionsBuilder);
  }

  function test_GetQueuedActionBuilders_WhenThereAreNoActionBuildersInTheQueue() external view {
    // it returns an empty array
    assertEq(canonGuard.getQueuedActionBuilders().length, 0);
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
    _assumeFuzzable(_actionsBuilder);
    vm.prank(SAFE);
    canonGuard.approveActionsBuilderOrHub(_actionsBuilder, ACTIONS_BUILDER_APPROVAL_DURATION);
    _;
  }
}
