// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';
import {CanonGuardFactory} from 'src/contracts/factories/CanonGuardFactory.sol';
import {ICanonGuard} from 'src/interfaces/ICanonGuard.sol';
import {ISafeManageable} from 'src/interfaces/ISafeManageable.sol';
import {ICanonGuardFactory} from 'src/interfaces/factories/ICanonGuardFactory.sol';
import {Utils} from 'test/unit/utils/Utils.sol';

contract UnitCanonGuardFactory is Test, Utils {
  CanonGuardFactory public canonGuardFactory;
  ICanonGuard public auxCanonGuard;
  address public multiSendCallOnly;
  uint256 public constant MIN_EXPIRY_TIME = 1 days;

  function setUp() external {
    multiSendCallOnly = makeAddr('multiSendCallOnly');
    canonGuardFactory = new CanonGuardFactory(multiSendCallOnly);
  }

  function test_Constructor_WhenCalled() external view {
    // it should store the multi send call only address
    assertEq(canonGuardFactory.MULTI_SEND_CALL_ONLY(), multiSendCallOnly);
  }

  function test_CreateCanonGuard_WhenCalledWithValidParameters(
    address _safe,
    uint256 _shortTxExecutionDelay,
    uint256 _longTxExecutionDelay,
    uint256 _txExpiryDelay,
    uint256 _maxApprovalDuration,
    address _emergencyTrigger,
    address _emergencyCaller
  ) external {
    vm.assume(_emergencyTrigger != address(0));
    vm.assume(_emergencyCaller != address(0));

    _txExpiryDelay = bound(_txExpiryDelay, MIN_EXPIRY_TIME, type(uint128).max);
    _maxApprovalDuration = bound(_maxApprovalDuration, MIN_EXPIRY_TIME, type(uint256).max);
    _shortTxExecutionDelay = bound(_shortTxExecutionDelay, 0, type(uint128).max - 1);
    _longTxExecutionDelay = bound(_longTxExecutionDelay, _shortTxExecutionDelay, type(uint128).max);

    // it should emit CanonGuardCreated event with correct parameters
    vm.expectEmit();
    emit ICanonGuardFactory.CanonGuardCreated(
      _getNextContractDeployedAddress(address(canonGuardFactory)),
      _safe,
      _emergencyTrigger,
      _emergencyCaller,
      address(this)
    );

    address _canonGuard = canonGuardFactory.createCanonGuard(
      _safe,
      _shortTxExecutionDelay,
      _longTxExecutionDelay,
      _txExpiryDelay,
      _maxApprovalDuration,
      _emergencyTrigger,
      _emergencyCaller
    );
    auxCanonGuard = ICanonGuard(
      deployCode(
        'CanonGuard',
        abi.encode(
          address(canonGuardFactory),
          _safe,
          multiSendCallOnly,
          _shortTxExecutionDelay,
          _longTxExecutionDelay,
          _txExpiryDelay,
          _maxApprovalDuration,
          _emergencyTrigger,
          _emergencyCaller
        )
      )
    );

    // it should deploy a new CanonGuard
    assertEq(address(auxCanonGuard).code, _canonGuard.code);

    // it should match the parameters sent to the constructor
    assertEq(address(ISafeManageable(_canonGuard).SAFE()), _safe);
    assertEq(ICanonGuard(_canonGuard).MULTI_SEND_CALL_ONLY(), multiSendCallOnly);
    assertEq(ICanonGuard(_canonGuard).SHORT_TX_EXECUTION_DELAY(), _shortTxExecutionDelay);
    assertEq(ICanonGuard(_canonGuard).LONG_TX_EXECUTION_DELAY(), _longTxExecutionDelay);
    assertEq(ICanonGuard(_canonGuard).TX_EXPIRY_DELAY(), _txExpiryDelay);
    assertEq(ICanonGuard(_canonGuard).MAX_APPROVAL_DURATION(), _maxApprovalDuration);

    // it should set the parent address in the child contract
    assertEq(ICanonGuard(_canonGuard).PARENT(), address(canonGuardFactory));

    // it should store the contract as a factory children
    assertTrue(canonGuardFactory.isChild(_canonGuard));
  }

  function test_CreateCanonGuard_WhenTheTransactionExpiryDelayIsLessThanTheMinimumExpiryTime(
    address _safe,
    uint256 _shortTxExecutionDelay,
    uint256 _longTxExecutionDelay,
    uint256 _txExpiryDelay,
    uint256 _maxApprovalDuration,
    address _emergencyTrigger,
    address _emergencyCaller
  ) external {
    _txExpiryDelay = bound(_txExpiryDelay, 0, canonGuardFactory.MIN_EXPIRY_TIME() - 1);
    // it reverts
    vm.expectRevert(ICanonGuardFactory.TxExpiryDelayCannotBeLessThanMin.selector);
    canonGuardFactory.createCanonGuard(
      _safe,
      _shortTxExecutionDelay,
      _longTxExecutionDelay,
      _txExpiryDelay,
      _maxApprovalDuration,
      _emergencyTrigger,
      _emergencyCaller
    );
  }

  function test_CreateCanonGuard_WhenTheMaximumApprovalDurationIsLessThanTheMinimumExpiryTime(
    address _safe,
    uint256 _shortTxExecutionDelay,
    uint256 _longTxExecutionDelay,
    uint256 _txExpiryDelay,
    uint256 _maxApprovalDuration,
    address _emergencyTrigger,
    address _emergencyCaller
  ) external {
    _txExpiryDelay = bound(_txExpiryDelay, canonGuardFactory.MIN_EXPIRY_TIME(), type(uint128).max);
    _maxApprovalDuration = bound(_maxApprovalDuration, 0, canonGuardFactory.MIN_EXPIRY_TIME() - 1);
    // it reverts
    vm.expectRevert(ICanonGuardFactory.MaxApprovalDurationCannotBeLessThanMin.selector);
    canonGuardFactory.createCanonGuard(
      _safe,
      _shortTxExecutionDelay,
      _longTxExecutionDelay,
      _txExpiryDelay,
      _maxApprovalDuration,
      _emergencyTrigger,
      _emergencyCaller
    );
  }
}
