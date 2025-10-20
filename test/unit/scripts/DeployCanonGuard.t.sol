// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AllowanceClaimorFactory} from 'contracts/factories/AllowanceClaimorFactory.sol';
import {ApproveActionFactory} from 'contracts/factories/ApproveActionFactory.sol';
import {CappedTokenTransfersHubFactory} from 'contracts/factories/CappedTokenTransfersHubFactory.sol';
import {ChangeSafeGuardActionFactory} from 'contracts/factories/ChangeSafeGuardActionFactory.sol';
import {EverclearTokenConversionFactory} from 'contracts/factories/EverclearTokenConversionFactory.sol';
import {OPxActionFactory} from 'contracts/factories/OPxActionFactory.sol';
import {SetEmergencyCallerActionFactory} from 'contracts/factories/SetEmergencyCallerActionFactory.sol';
import {SetEmergencyTriggerActionFactory} from 'contracts/factories/SetEmergencyTriggerActionFactory.sol';
import {SimpleActionsFactory} from 'contracts/factories/SimpleActionsFactory.sol';
import {SimpleTransfersFactory} from 'contracts/factories/SimpleTransfersFactory.sol';
import {Test} from 'forge-std/Test.sol';
import {ICanonGuardFactory} from 'interfaces/factories/ICanonGuardFactory.sol';
import {DeployCanonGuard} from 'script/DeployCanonGuard.s.sol';

contract UnitDeployCanonGuard is DeployCanonGuard, Test {
  ICanonGuardFactory internal _auxCanonGuardFactory;

  function setUp() public {
    // Deploy the DeployCanonGuard contract
    run();

    // Deploy the CanonGuardFactory contract
    _auxCanonGuardFactory = ICanonGuardFactory(deployCode('CanonGuardFactory', abi.encode(MULTI_SEND_CALL_ONLY)));
  }

  function test_WhenDeployingToEthereumMainnet() external {
    vm.chainId(ETHEREUM_MAINNET_CHAIN_ID);

    run();

    // it should deploy the common factories
    _assertCommonFactories();

    // it should deploy the ethereum factories
    assertEq(address(everclearTokenConversionFactory).code, type(EverclearTokenConversionFactory).runtimeCode);
  }

  function test_WhenDeployingToOptimismMainnet() external {
    vm.chainId(OPTIMISM_MAINNET_CHAIN_ID);

    run();

    // it should deploy the common factories
    _assertCommonFactories();

    // it should deploy the optimism factories
    assertEq(address(opxActionFactory).code, type(OPxActionFactory).runtimeCode);
  }

  function test_WhenDeployingToOtherChains(uint64 _chainId) external {
    vm.assume(_chainId != ETHEREUM_MAINNET_CHAIN_ID && _chainId != OPTIMISM_MAINNET_CHAIN_ID);
    vm.chainId(_chainId);

    run();

    // it should deploy the common factories
    _assertCommonFactories();
  }

  function _assertCommonFactories() private view {
    assertEq(address(allowanceClaimorFactory).code, type(AllowanceClaimorFactory).runtimeCode);
    assertEq(address(approveActionFactory).code, type(ApproveActionFactory).runtimeCode);
    assertEq(address(canonGuardFactory).code, address(_auxCanonGuardFactory).code);
    assertEq(canonGuardFactory.MULTI_SEND_CALL_ONLY(), address(MULTI_SEND_CALL_ONLY));
    assertEq(address(cappedTokenTransfersHubFactory).code, type(CappedTokenTransfersHubFactory).runtimeCode);
    assertEq(address(changeSafeGuardActionFactory).code, type(ChangeSafeGuardActionFactory).runtimeCode);
    assertEq(address(setEmergencyCallerActionFactory).code, type(SetEmergencyCallerActionFactory).runtimeCode);
    assertEq(address(setEmergencyTriggerActionFactory).code, type(SetEmergencyTriggerActionFactory).runtimeCode);
    assertEq(address(simpleActionsFactory).code, type(SimpleActionsFactory).runtimeCode);
    assertEq(address(simpleTransfersFactory).code, type(SimpleTransfersFactory).runtimeCode);
  }
}
