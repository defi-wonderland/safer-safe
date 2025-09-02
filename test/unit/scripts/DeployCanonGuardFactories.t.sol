// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from 'forge-std/Test.sol';

import {DeployCanonGuardFactories} from 'script/DeployCanonGuardFactories.s.sol';

import {AllowanceClaimorFactory} from 'contracts/factories/AllowanceClaimorFactory.sol';
import {CappedTokenTransfersHubFactory} from 'contracts/factories/CappedTokenTransfersHubFactory.sol';
import {SimpleActionsFactory} from 'contracts/factories/SimpleActionsFactory.sol';
import {SimpleTransfersFactory} from 'contracts/factories/SimpleTransfersFactory.sol';

import {IAllowanceClaimorFactory} from 'interfaces/factories/IAllowanceClaimorFactory.sol';

import {ICanonGuardFactory} from 'interfaces/factories/ICanonGuardFactory.sol';
import {ICappedTokenTransfersHubFactory} from 'interfaces/factories/ICappedTokenTransfersHubFactory.sol';
import {ISimpleActionsFactory} from 'interfaces/factories/ISimpleActionsFactory.sol';
import {ISimpleTransfersFactory} from 'interfaces/factories/ISimpleTransfersFactory.sol';

import {Constants} from 'script/Constants.sol';

contract UnitDeployCanonGuardFactories is Constants, Test {
  DeployCanonGuardFactories public deployCanonGuardFactories;

  ICanonGuardFactory internal _auxCanonGuardFactory;

  function setUp() public {
    // Deploy the DeployCanonGuardFactories contract
    deployCanonGuardFactories = new DeployCanonGuardFactories();

    // Deploy the CanonGuardFactory contract
    _auxCanonGuardFactory = ICanonGuardFactory(deployCode('CanonGuardFactory', abi.encode(MULTI_SEND_CALL_ONLY)));
  }

  function test_WhenRun() public {
    // Run the deployment script
    deployCanonGuardFactories.deployCanonGuardFactories();

    // Get the deployed contracts
    ICanonGuardFactory _canonGuardFactory = deployCanonGuardFactories.canonGuardFactory();
    IAllowanceClaimorFactory _allowanceClaimorFactory = deployCanonGuardFactories.allowanceClaimorFactory();
    ICappedTokenTransfersHubFactory _cappedTokenTransfersHubFactory =
      deployCanonGuardFactories.cappedTokenTransfersHubFactory();
    ISimpleActionsFactory _simpleActionsFactory = deployCanonGuardFactories.simpleActionsFactory();
    ISimpleTransfersFactory _simpleTransfersFactory = deployCanonGuardFactories.simpleTransfersFactory();

    // It should deploy the CanonGuardFactory contract with correct args
    assertEq(address(_canonGuardFactory).code, address(_auxCanonGuardFactory).code);
    assertEq(_canonGuardFactory.MULTI_SEND_CALL_ONLY(), address(MULTI_SEND_CALL_ONLY));

    // It should deploy the AllowanceClaimorFactory contract
    assertEq(address(_allowanceClaimorFactory).code, type(AllowanceClaimorFactory).runtimeCode);

    // It should deploy the CappedTokenTransfersHubFactory contract
    assertEq(address(_cappedTokenTransfersHubFactory).code, type(CappedTokenTransfersHubFactory).runtimeCode);

    // It should deploy the SimpleActionsFactory contract
    assertEq(address(_simpleActionsFactory).code, type(SimpleActionsFactory).runtimeCode);

    // It should deploy the SimpleTransfersFactory contract
    assertEq(address(_simpleTransfersFactory).code, type(SimpleTransfersFactory).runtimeCode);
  }
}
