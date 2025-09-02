// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {Test} from 'forge-std/Test.sol';
import {SafeEntrypointFactory} from 'src/contracts/factories/SafeEntrypointFactory.sol';
import {ISafeEntrypoint} from 'src/interfaces/ISafeEntrypoint.sol';
import {ISafeManageable} from 'src/interfaces/ISafeManageable.sol';

contract UnitSafeEntrypointFactory is Test {
  SafeEntrypointFactory public safeEntrypointFactory;
  ISafeEntrypoint public auxSafeEntrypoint;
  address public multiSendCallOnly;
  uint256 public constant MIN_EXPIRY_TIME = 1 days;

  function setUp() external {
    multiSendCallOnly = makeAddr('multiSendCallOnly');
    safeEntrypointFactory = new SafeEntrypointFactory(multiSendCallOnly);
  }

  function test_ConstructorWhenCalled() external view {
    // it should deploy a new SafeEntrypointFactory with correct parameters
    assertEq(safeEntrypointFactory.MULTI_SEND_CALL_ONLY(), multiSendCallOnly);
  }

  function test_CreateSafeEntrypointWhenCalled(
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

    address _safeEntrypoint = safeEntrypointFactory.createSafeEntrypoint(
      _safe,
      _shortTxExecutionDelay,
      _longTxExecutionDelay,
      _txExpiryDelay,
      _maxApprovalDuration,
      _emergencyTrigger,
      _emergencyCaller
    );
    auxSafeEntrypoint = ISafeEntrypoint(
      deployCode(
        'SafeEntrypoint',
        abi.encode(
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

    // it should deploy a new SafeEntrypoint
    assertEq(address(auxSafeEntrypoint).code, _safeEntrypoint.code);

    // it should match the parameters sent to the constructor
    assertEq(address(ISafeManageable(_safeEntrypoint).SAFE()), _safe);
    assertEq(ISafeEntrypoint(_safeEntrypoint).MULTI_SEND_CALL_ONLY(), multiSendCallOnly);
    assertEq(ISafeEntrypoint(_safeEntrypoint).SHORT_TX_EXECUTION_DELAY(), _shortTxExecutionDelay);
    assertEq(ISafeEntrypoint(_safeEntrypoint).LONG_TX_EXECUTION_DELAY(), _longTxExecutionDelay);
    assertEq(ISafeEntrypoint(_safeEntrypoint).TX_EXPIRY_DELAY(), _txExpiryDelay);
    assertEq(ISafeEntrypoint(_safeEntrypoint).MAX_APPROVAL_DURATION(), _maxApprovalDuration);
  }
}
