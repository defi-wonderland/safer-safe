// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AllowanceClaimorFactory} from 'contracts/factories/AllowanceClaimorFactory.sol';
import {ApproveActionFactory} from 'contracts/factories/ApproveActionFactory.sol';
import {CappedTokenTransfersHubFactory} from 'contracts/factories/CappedTokenTransfersHubFactory.sol';
import {ChangeSafeGuardActionFactory} from 'contracts/factories/ChangeSafeGuardActionFactory.sol';
import {DisapproveActionFactory} from 'contracts/factories/DisapproveActionFactory.sol';
import {DisapproveActionFactory} from 'contracts/factories/DisapproveActionFactory.sol';
import {EverclearTokenConversionFactory} from 'contracts/factories/EverclearTokenConversionFactory.sol';
import {EverclearTokenStakeFactory} from 'contracts/factories/EverclearTokenStakeFactory.sol';
import {EverclearTokenStakeFactory} from 'contracts/factories/EverclearTokenStakeFactory.sol';
import {OPxActionFactory} from 'contracts/factories/OPxActionFactory.sol';
import {SetEmergencyCallerActionFactory} from 'contracts/factories/SetEmergencyCallerActionFactory.sol';
import {SetEmergencyTriggerActionFactory} from 'contracts/factories/SetEmergencyTriggerActionFactory.sol';
import {SimpleActionsFactory} from 'contracts/factories/SimpleActionsFactory.sol';
import {SimpleTransfersFactory} from 'contracts/factories/SimpleTransfersFactory.sol';
import {UnsetEmergencyModeActionFactory} from 'contracts/factories/UnsetEmergencyModeActionFactory.sol';
import {Test} from 'forge-std/Test.sol';
import {IAllowanceClaimorFactory} from 'interfaces/factories/IAllowanceClaimorFactory.sol';
import {IApproveActionFactory} from 'interfaces/factories/IApproveActionFactory.sol';
import {ICanonGuardFactory} from 'interfaces/factories/ICanonGuardFactory.sol';
import {ICappedTokenTransfersHubFactory} from 'interfaces/factories/ICappedTokenTransfersHubFactory.sol';
import {IChangeSafeGuardActionFactory} from 'interfaces/factories/IChangeSafeGuardActionFactory.sol';
import {IDisapproveActionFactory} from 'interfaces/factories/IDisapproveActionFactory.sol';
import {IEverclearTokenConversionFactory} from 'interfaces/factories/IEverclearTokenConversionFactory.sol';
import {IEverclearTokenStakeFactory} from 'interfaces/factories/IEverclearTokenStakeFactory.sol';
import {IOPxActionFactory} from 'interfaces/factories/IOPxActionFactory.sol';
import {ISetEmergencyCallerActionFactory} from 'interfaces/factories/ISetEmergencyCallerActionFactory.sol';
import {ISetEmergencyTriggerActionFactory} from 'interfaces/factories/ISetEmergencyTriggerActionFactory.sol';
import {ISimpleActionsFactory} from 'interfaces/factories/ISimpleActionsFactory.sol';
import {ISimpleTransfersFactory} from 'interfaces/factories/ISimpleTransfersFactory.sol';
import {IUnsetEmergencyModeActionFactory} from 'interfaces/factories/IUnsetEmergencyModeActionFactory.sol';
// import {Constants} from 'script/Constants.sol';

import {ICanonGuard} from 'interfaces/ICanonGuard.sol';
import {DeployCanonGuard} from 'script/DeployCanonGuard.s.sol';

contract UnitDeployCanonGuard is DeployCanonGuard, Test {
  // IAllowanceClaimorFactory public allowanceClaimorFactory;
  // IApproveActionFactory public approveActionFactory;
  // ICanonGuardFactory public canonGuardFactory;
  // ICappedTokenTransfersHubFactory public cappedTokenTransfersHubFactory;
  // IChangeSafeGuardActionFactory public changeSafeGuardActionFactory;
  // IDisapproveActionFactory public disapproveActionFactory;
  // IEverclearTokenConversionFactory public everclearTokenConversionFactory;
  // IEverclearTokenStakeFactory public everclearTokenStakeFactory;
  // IOPxActionFactory public opxActionFactory;
  // ISetEmergencyCallerActionFactory public setEmergencyCallerActionFactory;
  // ISetEmergencyTriggerActionFactory public setEmergencyTriggerActionFactory;
  // ISimpleActionsFactory public simpleActionsFactory;
  // ISimpleTransfersFactory public simpleTransfersFactory;
  // IUnsetEmergencyModeActionFactory public unsetEmergencyModeActionFactory;

  // DeployCanonGuard public deployCanonGuard;

  ICanonGuardFactory internal _auxCanonGuardFactory;
  ICanonGuard internal _auxCanonGuard;

  function setUp() public {
    // Deploy the DeployCanonGuard contract
    run();

    // Deploy the CanonGuardFactory contract
    _auxCanonGuardFactory = ICanonGuardFactory(deployCode('CanonGuardFactory', abi.encode(MULTI_SEND_CALL_ONLY)));

    // Deploy the CanonGuard contract
    _auxCanonGuard = ICanonGuard(
      deployCode(
        'CanonGuard',
        abi.encode(
          address(canonGuardFactory),
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
  }

  function test_WhenDeployingToEthereumMainnet() external {
    vm.chainId(ETHEREUM_MAINNET_CHAIN_ID);

    run();

    _loadDeployedFactories();

    // it should deploy the common factories
    _assertCommonFactories();

    // it should deploy the ethereum factories
    assertEq(address(everclearTokenConversionFactory).code, type(EverclearTokenConversionFactory).runtimeCode);
    assertEq(address(everclearTokenStakeFactory).code, type(EverclearTokenStakeFactory).runtimeCode);
  }

  function test_WhenDeployingToOptimismMainnet() external {
    vm.chainId(OPTIMISM_MAINNET_CHAIN_ID);

    run();

    _loadDeployedFactories();

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

    // it should deploy the CanonGuard contract with correct args
    // assertEq(address(canonGuard).code, address(_auxCanonGuard).code);
    assertEq(address(canonGuard.SAFE()), address(SAFE_PROXY));
    assertEq(canonGuard.MULTI_SEND_CALL_ONLY(), address(MULTI_SEND_CALL_ONLY));
    assertEq(canonGuard.SHORT_TX_EXECUTION_DELAY(), SHORT_TX_EXECUTION_DELAY);
    assertEq(canonGuard.LONG_TX_EXECUTION_DELAY(), LONG_TX_EXECUTION_DELAY);
    assertEq(canonGuard.TX_EXPIRY_DELAY(), TX_EXPIRY_DELAY);
    assertEq(canonGuard.MAX_APPROVAL_DURATION(), MAX_APPROVAL_DURATION);
  }

  function _assertCommonFactories() private view {
    assertEq(address(allowanceClaimorFactory).code, type(AllowanceClaimorFactory).runtimeCode);
    assertEq(address(approveActionFactory).code, type(ApproveActionFactory).runtimeCode);
    assertEq(address(canonGuardFactory).code, address(_auxCanonGuardFactory).code);
    assertEq(canonGuardFactory.MULTI_SEND_CALL_ONLY(), address(MULTI_SEND_CALL_ONLY));
    assertEq(address(cappedTokenTransfersHubFactory).code, type(CappedTokenTransfersHubFactory).runtimeCode);
    assertEq(address(changeSafeGuardActionFactory).code, type(ChangeSafeGuardActionFactory).runtimeCode);
    assertEq(address(disapproveActionFactory).code, type(DisapproveActionFactory).runtimeCode);
    assertEq(address(setEmergencyCallerActionFactory).code, type(SetEmergencyCallerActionFactory).runtimeCode);
    assertEq(address(setEmergencyTriggerActionFactory).code, type(SetEmergencyTriggerActionFactory).runtimeCode);
    assertEq(address(simpleActionsFactory).code, type(SimpleActionsFactory).runtimeCode);
    assertEq(address(simpleTransfersFactory).code, type(SimpleTransfersFactory).runtimeCode);
    assertEq(address(unsetEmergencyModeActionFactory).code, type(UnsetEmergencyModeActionFactory).runtimeCode);
  }

  function _loadDeployedFactories() private {
    // allowanceClaimorFactory = deployCanonGuard.allowanceClaimorFactory();
    // approveActionFactory = deployCanonGuard.approveActionFactory();
    // canonGuardFactory = deployCanonGuard.canonGuardFactory();
    // cappedTokenTransfersHubFactory = deployCanonGuard.cappedTokenTransfersHubFactory();
    // changeSafeGuardActionFactory = deployCanonGuard.changeSafeGuardActionFactory();
    // disapproveActionFactory = deployCanonGuard.disapproveActionFactory();
    // everclearTokenConversionFactory = deployCanonGuard.everclearTokenConversionFactory();
    // everclearTokenStakeFactory = deployCanonGuard.everclearTokenStakeFactory();
    // opxActionFactory = deployCanonGuard.opxActionFactory();
    // setEmergencyCallerActionFactory = deployCanonGuard.setEmergencyCallerActionFactory();
    // setEmergencyTriggerActionFactory = deployCanonGuard.setEmergencyTriggerActionFactory();
    // simpleActionsFactory = deployCanonGuard.simpleActionsFactory();
    // simpleTransfersFactory = deployCanonGuard.simpleTransfersFactory();
    // unsetEmergencyModeActionFactory = deployCanonGuard.unsetEmergencyModeActionFactory();
  }
}
