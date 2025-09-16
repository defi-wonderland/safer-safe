// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

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
import {Constants} from 'script/Constants.sol';
import {DeployCanonGuardFactories} from 'script/DeployCanonGuardFactories.s.sol';

contract UnitDeployCanonGuardFactories is Constants, Test {
  IAllowanceClaimorFactory public allowanceClaimorFactory;
  IApproveActionFactory public approveActionFactory;
  ICanonGuardFactory public canonGuardFactory;
  ICappedTokenTransfersHubFactory public cappedTokenTransfersHubFactory;
  IChangeSafeGuardActionFactory public changeSafeGuardActionFactory;
  IDisapproveActionFactory public disapproveActionFactory;
  IEverclearTokenConversionFactory public everclearTokenConversionFactory;
  IEverclearTokenStakeFactory public everclearTokenStakeFactory;
  IOPxActionFactory public opxActionFactory;
  ISetEmergencyCallerActionFactory public setEmergencyCallerActionFactory;
  ISetEmergencyTriggerActionFactory public setEmergencyTriggerActionFactory;
  ISimpleActionsFactory public simpleActionsFactory;
  ISimpleTransfersFactory public simpleTransfersFactory;
  IUnsetEmergencyModeActionFactory public unsetEmergencyModeActionFactory;

  DeployCanonGuardFactories public deployCanonGuardFactories;
  ICanonGuardFactory internal _auxCanonGuardFactory;

  function setUp() public {
    // Deploy the DeployCanonGuardFactories contract
    deployCanonGuardFactories = new DeployCanonGuardFactories();

    // Deploy the CanonGuardFactory contract
    _auxCanonGuardFactory = ICanonGuardFactory(deployCode('CanonGuardFactory', abi.encode(MULTI_SEND_CALL_ONLY)));
  }

  function test_WhenDeployingToEthereumMainnet() external {
    vm.chainId(ETHEREUM_MAINNET_CHAIN_ID);

    deployCanonGuardFactories.deployCanonGuardFactories();

    _loadDeployedFactories();

    // it should deploy the common factories
    _assertCommonFactories();

    // it should deploy the ethereum factories
    assertEq(address(everclearTokenConversionFactory).code, type(EverclearTokenConversionFactory).runtimeCode);
    assertEq(address(everclearTokenStakeFactory).code, type(EverclearTokenStakeFactory).runtimeCode);
  }

  function test_WhenDeployingToOptimismMainnet() external {
    vm.chainId(OPTIMISM_MAINNET_CHAIN_ID);

    deployCanonGuardFactories.deployCanonGuardFactories();

    _loadDeployedFactories();

    // it should deploy the common factories
    _assertCommonFactories();

    // it should deploy the optimism factories
    assertEq(address(opxActionFactory).code, type(OPxActionFactory).runtimeCode);
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
    allowanceClaimorFactory = deployCanonGuardFactories.allowanceClaimorFactory();
    approveActionFactory = deployCanonGuardFactories.approveActionFactory();
    canonGuardFactory = deployCanonGuardFactories.canonGuardFactory();
    cappedTokenTransfersHubFactory = deployCanonGuardFactories.cappedTokenTransfersHubFactory();
    changeSafeGuardActionFactory = deployCanonGuardFactories.changeSafeGuardActionFactory();
    disapproveActionFactory = deployCanonGuardFactories.disapproveActionFactory();
    everclearTokenConversionFactory = deployCanonGuardFactories.everclearTokenConversionFactory();
    everclearTokenStakeFactory = deployCanonGuardFactories.everclearTokenStakeFactory();
    opxActionFactory = deployCanonGuardFactories.opxActionFactory();
    setEmergencyCallerActionFactory = deployCanonGuardFactories.setEmergencyCallerActionFactory();
    setEmergencyTriggerActionFactory = deployCanonGuardFactories.setEmergencyTriggerActionFactory();
    simpleActionsFactory = deployCanonGuardFactories.simpleActionsFactory();
    simpleTransfersFactory = deployCanonGuardFactories.simpleTransfersFactory();
    unsetEmergencyModeActionFactory = deployCanonGuardFactories.unsetEmergencyModeActionFactory();
  }
}
