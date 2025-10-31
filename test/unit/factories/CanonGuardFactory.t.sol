// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';
import {Constants} from 'script/Constants.sol';
import {CanonGuardFactory} from 'src/contracts/factories/CanonGuardFactory.sol';
import {ICanonGuard} from 'src/interfaces/ICanonGuard.sol';
import {ISafeManageable} from 'src/interfaces/ISafeManageable.sol';
import {ICanonGuardFactory} from 'src/interfaces/factories/ICanonGuardFactory.sol';
import {Utils} from 'test/unit/utils/Utils.sol';

contract UnitCanonGuardFactorycreateCanonGuard is Test, Constants, Utils {
  CanonGuardFactory public canonGuardFactory;
  ICanonGuard public auxCanonGuard;
  uint256 public constant MIN_EXPIRY_TIME = 1 hours;

  function setUp() external {
    canonGuardFactory = new CanonGuardFactory();

    vm.etch(address(CREATE_X), _getCreateXDeployedBytecode());
  }

  function test_WhenCalledWithValidParameters(
    address _safe,
    address _multiSendCallOnly,
    uint256 _shortTxExecutionDelay,
    uint256 _longTxExecutionDelay,
    uint256 _txExpiryDelay,
    uint256 _maxApprovalDuration,
    address _emergencyTrigger,
    address _emergencyCaller
  ) external {
    vm.assume(_emergencyTrigger != address(0));
    vm.assume(_emergencyCaller != address(0));
    vm.assume(_multiSendCallOnly != address(0));

    _txExpiryDelay = bound(_txExpiryDelay, MIN_EXPIRY_TIME, type(uint128).max);
    _maxApprovalDuration = bound(_maxApprovalDuration, MIN_EXPIRY_TIME, type(uint256).max);
    _shortTxExecutionDelay = bound(_shortTxExecutionDelay, 0, 6 * 30 days);
    _longTxExecutionDelay = bound(_longTxExecutionDelay, _shortTxExecutionDelay, 6 * 30 days);

    // NOTE: hashing twice because of safeguard mechanism in the CreateX contract (https://github.com/pcaversaccio/createx/blob/main/src/CreateX.sol#L908-L910)
    address _expectedCanonGuard = CREATE_X.computeCreate3Address(keccak256(abi.encode(keccak256(abi.encode(_safe)))));

    // it should emit CanonGuardCreated event with correct parameters
    vm.expectEmit();
    emit ICanonGuardFactory.CanonGuardCreated(_expectedCanonGuard, _safe, _emergencyTrigger, _emergencyCaller);

    vm.prank(_safe);
    address _canonGuard = canonGuardFactory.createCanonGuard(
      _safe,
      _multiSendCallOnly,
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
          _multiSendCallOnly,
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
    assertEq(ICanonGuard(_canonGuard).MULTI_SEND_CALL_ONLY(), _multiSendCallOnly);
    assertEq(ICanonGuard(_canonGuard).SHORT_TX_EXECUTION_DELAY(), _shortTxExecutionDelay);
    assertEq(ICanonGuard(_canonGuard).LONG_TX_EXECUTION_DELAY(), _longTxExecutionDelay);
    assertEq(ICanonGuard(_canonGuard).TX_EXPIRY_DELAY(), _txExpiryDelay);
    assertEq(ICanonGuard(_canonGuard).MAX_APPROVAL_DURATION(), _maxApprovalDuration);

    // it should set the parent address in the child contract
    assertEq(ICanonGuard(_canonGuard).PARENT(), address(canonGuardFactory));

    // it should store the contract as a factory children
    assertTrue(canonGuardFactory.isChild(_canonGuard));

    // it should match the deterministic address
    assertEq(_canonGuard, _expectedCanonGuard);
  }

  function test_WhenTheMultiSendCallOnlyAddressIsZero(address _safe) external {
    // it reverts
    vm.prank(_safe);
    vm.expectRevert(ICanonGuardFactory.MultiSendCallOnlyCannotBeZero.selector);
    canonGuardFactory.createCanonGuard(_safe, address(0), 0, 0, 0, 0, address(0), address(0));
  }

  function test_WhenTheDeployerIsNotTheSafeContract(address _deployer, address _safe) external {
    vm.assume(_deployer != _safe);

    // it reverts
    vm.expectRevert(ICanonGuardFactory.DeployerMustBeTheSafe.selector);
    vm.prank(_deployer);
    canonGuardFactory.createCanonGuard(_safe, address(0), 0, 0, 0, 0, address(0), address(0));
  }
}
