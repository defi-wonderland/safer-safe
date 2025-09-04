// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {Test} from 'forge-std/Test.sol';
import {CanonGuardFactory} from 'src/contracts/factories/CanonGuardFactory.sol';
import {ICanonGuard} from 'src/interfaces/ICanonGuard.sol';
import {ISafeManageable} from 'src/interfaces/ISafeManageable.sol';

contract UnitCanonGuardFactory is Test {
  CanonGuardFactory public canonGuardFactory;
  ICanonGuard public auxCanonGuard;
  address public multiSendCallOnly;

  function setUp() external {
    multiSendCallOnly = makeAddr('multiSendCallOnly');
    canonGuardFactory = new CanonGuardFactory(multiSendCallOnly);
  }

  function test_ConstructorWhenCalled() external view {
    // it should store the multi send call only address
    assertEq(canonGuardFactory.MULTI_SEND_CALL_ONLY(), multiSendCallOnly);
  }

  function test_CreateCanonGuardWhenCalled(
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

    // it should set the factory address in the child contract
    assertEq(ICanonGuard(_canonGuard).FACTORY(), address(canonGuardFactory));

    // it should store the contract as a factory children
    assertTrue(canonGuardFactory.isChild(_canonGuard));
  }
}
