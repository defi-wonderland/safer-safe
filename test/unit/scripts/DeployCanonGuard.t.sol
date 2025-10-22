// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AllowanceClaimor} from 'contracts/actions-builders/AllowanceClaimor.sol';
import {CappedTokenTransfers} from 'contracts/actions-builders/CappedTokenTransfers.sol';
import {ChangeSafeGuardAction} from 'contracts/actions-builders/ChangeSafeGuardAction.sol';
import {PreApproveAction} from 'contracts/actions-builders/PreApproveAction.sol';
import {SetEmergencyCallerAction} from 'contracts/actions-builders/SetEmergencyCallerAction.sol';
import {SetEmergencyTriggerAction} from 'contracts/actions-builders/SetEmergencyTriggerAction.sol';
import {SimpleActions} from 'contracts/actions-builders/SimpleActions.sol';
import {SimpleTransfers} from 'contracts/actions-builders/SimpleTransfers.sol';
import {UnsetEmergencyModeAction} from 'contracts/actions-builders/UnsetEmergencyModeAction.sol';
import {AllowanceClaimorFactory} from 'contracts/factories/AllowanceClaimorFactory.sol';
import {CappedTokenTransfersHubFactory} from 'contracts/factories/CappedTokenTransfersHubFactory.sol';
import {ChangeSafeGuardActionFactory} from 'contracts/factories/ChangeSafeGuardActionFactory.sol';
import {EverclearTokenConversionFactory} from 'contracts/factories/EverclearTokenConversionFactory.sol';
import {OPxActionFactory} from 'contracts/factories/OPxActionFactory.sol';
import {PreApproveActionFactory} from 'contracts/factories/PreApproveActionFactory.sol';
import {SetEmergencyCallerActionFactory} from 'contracts/factories/SetEmergencyCallerActionFactory.sol';
import {SetEmergencyTriggerActionFactory} from 'contracts/factories/SetEmergencyTriggerActionFactory.sol';
import {SimpleActionsFactory} from 'contracts/factories/SimpleActionsFactory.sol';
import {SimpleTransfersFactory} from 'contracts/factories/SimpleTransfersFactory.sol';
import {Test} from 'forge-std/Test.sol';
import {ICanonGuardFactory} from 'interfaces/factories/ICanonGuardFactory.sol';
import {DeployCanonGuard} from 'script/DeployCanonGuard.s.sol';
import {CanonGuard} from 'src/contracts/CanonGuard.sol';
import {CappedTokenTransfersHub} from 'src/contracts/action-hubs/CappedTokenTransfersHub.sol';
import {SetGuardAction} from 'src/contracts/actions-builders/SetGuardAction.sol';

contract UnitDeployCanonGuard is DeployCanonGuard, Test {
  ICanonGuardFactory internal _auxCanonGuardFactory;

  function setUp() public {
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

    // it should deploy the common contracts for the chain
    _assertCommonContracts();
  }

  function _assertCommonFactories() private view {
    assertEq(address(allowanceClaimorFactory).code, type(AllowanceClaimorFactory).runtimeCode);
    assertEq(address(preApproveActionFactory).code, type(PreApproveActionFactory).runtimeCode);
    assertEq(address(canonGuardFactory).code, address(_auxCanonGuardFactory).code);
    assertEq(canonGuardFactory.MULTI_SEND_CALL_ONLY(), address(MULTI_SEND_CALL_ONLY));
    assertEq(address(cappedTokenTransfersHubFactory).code, type(CappedTokenTransfersHubFactory).runtimeCode);
    assertEq(address(changeSafeGuardActionFactory).code, type(ChangeSafeGuardActionFactory).runtimeCode);
    assertEq(address(setEmergencyCallerActionFactory).code, type(SetEmergencyCallerActionFactory).runtimeCode);
    assertEq(address(setEmergencyTriggerActionFactory).code, type(SetEmergencyTriggerActionFactory).runtimeCode);
    assertEq(address(simpleActionsFactory).code, type(SimpleActionsFactory).runtimeCode);
    assertEq(address(simpleTransfersFactory).code, type(SimpleTransfersFactory).runtimeCode);
  }

  function _assertCommonContracts() private {
    AllowanceClaimor _auxAllowanceClaimor = AllowanceClaimor(
      deployCode('AllowanceClaimor', abi.encode(DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_ADDRESS))
    );
    PreApproveAction _auxPreApproveAction = PreApproveAction(
      deployCode('PreApproveAction', abi.encode(DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_APPROVAL_DURATION))
    );
    // TODO: fix this
    // CappedTokenTransfers _auxCappedTokenTransfers = CappedTokenTransfers(
    //   deployCode(
    //     'CappedTokenTransfers', abi.encode(DUMMY_ADDRESS, DUMMY_AMOUNT, DUMMY_ADDRESS)
    //   )
    // );
    ChangeSafeGuardAction _auxChangeSafeGuardAction =
      ChangeSafeGuardAction(deployCode('ChangeSafeGuardAction', abi.encode(DUMMY_ADDRESS, DUMMY_ADDRESS)));
    SetEmergencyCallerAction _auxSetEmergencyCallerAction =
      SetEmergencyCallerAction(deployCode('SetEmergencyCallerAction', abi.encode(DUMMY_ADDRESS, DUMMY_ADDRESS)));
    SetEmergencyTriggerAction _auxSetEmergencyTriggerAction =
      SetEmergencyTriggerAction(deployCode('SetEmergencyTriggerAction', abi.encode(DUMMY_ADDRESS, DUMMY_ADDRESS)));
    SimpleActions _auxSimpleActions =
      SimpleActions(deployCode('SimpleActions', abi.encode(DUMMY_ADDRESS, new SimpleActions.SimpleAction[](0))));
    SimpleTransfers _auxSimpleTransfers = SimpleTransfers(
      deployCode('SimpleTransfers', abi.encode(DUMMY_ADDRESS, new SimpleTransfers.TransferAction[](0)))
    );
    CappedTokenTransfersHub _auxCappedTokenTransfersHub = CappedTokenTransfersHub(
      deployCode(
        'CappedTokenTransfersHub',
        abi.encode(DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_ADDRESS, new address[](0), new uint256[](0), DUMMY_EPOCH_LENGTH)
      )
    );
    CanonGuard _auxCanonGuard = CanonGuard(
      deployCode(
        'CanonGuard',
        abi.encode(
          DUMMY_ADDRESS,
          DUMMY_ADDRESS,
          DUMMY_ADDRESS,
          DUMMY_DELAY,
          DUMMY_DELAY * 2,
          DUMMY_DELAY,
          DUMMY_DELAY,
          DUMMY_ADDRESS,
          DUMMY_ADDRESS
        )
      )
    );
    SetGuardAction _auxSetGuardAction = SetGuardAction(deployCode('SetGuardAction'));
    UnsetEmergencyModeAction _auxUnsetEmergencyModeAction =
      UnsetEmergencyModeAction(deployCode('UnsetEmergencyModeAction'));

    assertEq(address(_allowanceClaimor).code, address(_auxAllowanceClaimor).code);
    assertEq(address(_preApproveAction).code, address(_auxPreApproveAction).code);
    // assertEq(address(_cappedTokenTransfers).code, address(_auxCappedTokenTransfers).code);
    assertEq(address(_changeSafeGuardAction).code, address(_auxChangeSafeGuardAction).code);
    assertEq(address(_setEmergencyCallerAction).code, address(_auxSetEmergencyCallerAction).code);
    assertEq(address(_setEmergencyTriggerAction).code, address(_auxSetEmergencyTriggerAction).code);
    assertEq(address(_simpleActions).code, address(_auxSimpleActions).code);
    assertEq(address(_simpleTransfers).code, address(_auxSimpleTransfers).code);
    assertEq(address(_cappedTokenTransfersHub).code, address(_auxCappedTokenTransfersHub).code);
    assertEq(address(_canonGuard).code, address(_auxCanonGuard).code);
    assertEq(address(setGuardAction).code, address(_auxSetGuardAction).code);
    assertEq(address(unsetEmergencyModeAction).code, address(_auxUnsetEmergencyModeAction).code);
  }
}
