// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';

import {DeployCanonGuard} from 'script/DeployCanonGuard.s.sol';

import {ICanonGuard} from 'interfaces/ICanonGuard.sol';

import {Constants} from 'script/Constants.sol';

contract UnitDeployCanonGuard is Constants, Test {
  DeployCanonGuard public deployCanonGuard;

  ICanonGuard internal _auxCanonGuard;

  function setUp() public {
    // Deploy the DeployCanonGuard contract
    deployCanonGuard = new DeployCanonGuard();

    // Deploy the CanonGuard contract
    _auxCanonGuard = ICanonGuard(
      deployCode(
        'CanonGuard',
        abi.encode(
          address(CANON_GUARD_FACTORY),
          SAFE_PROXY,
          MULTI_SEND_CALL_ONLY,
          SHORT_TX_EXECUTION_DELAY,
          LONG_TX_EXECUTION_DELAY,
          TX_EXPIRY_DELAY,
          MAX_APPROVAL_DURATION,
          EMERGENCY_TRIGGER,
          EMERGENCY_CALLER
        )
      )
    );

    // Deploy the CanonGuardFactory contract
    deployCodeTo('CanonGuardFactory', abi.encode(MULTI_SEND_CALL_ONLY), address(CANON_GUARD_FACTORY)); // TODO: Remove once deployed
  }

  function test_WhenRun() public {
    // Run the deployment script
    deployCanonGuard.deployCanonGuard();

    // Get the deployed contracts
    ICanonGuard _canonGuard = deployCanonGuard.canonGuard();

    // It should deploy the CanonGuard contract with correct args
    assertEq(address(_canonGuard).code, address(_auxCanonGuard).code);
    assertEq(address(_canonGuard.SAFE()), address(SAFE_PROXY));
    assertEq(_canonGuard.MULTI_SEND_CALL_ONLY(), address(MULTI_SEND_CALL_ONLY));
    assertEq(_canonGuard.SHORT_TX_EXECUTION_DELAY(), SHORT_TX_EXECUTION_DELAY);
    assertEq(_canonGuard.LONG_TX_EXECUTION_DELAY(), LONG_TX_EXECUTION_DELAY);
    assertEq(_canonGuard.TX_EXPIRY_DELAY(), TX_EXPIRY_DELAY);
    assertEq(_canonGuard.MAX_APPROVAL_DURATION(), MAX_APPROVAL_DURATION);
  }
}
