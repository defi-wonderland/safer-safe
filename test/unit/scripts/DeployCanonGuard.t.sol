// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';
import {ICanonGuard} from 'interfaces/ICanonGuard.sol';
import {ICappedTokenTransfersHub} from 'interfaces/action-hubs/ICappedTokenTransfersHub.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {IAllowanceClaimor} from 'interfaces/actions-builders/IAllowanceClaimor.sol';
import {ICappedTokenTransfers} from 'interfaces/actions-builders/ICappedTokenTransfers.sol';
import {IChangeSafeGuardAction} from 'interfaces/actions-builders/IChangeSafeGuardAction.sol';
import {IPreApproveAction} from 'interfaces/actions-builders/IPreApproveAction.sol';
import {ISetEmergencyCallerAction} from 'interfaces/actions-builders/ISetEmergencyCallerAction.sol';
import {ISetEmergencyTriggerAction} from 'interfaces/actions-builders/ISetEmergencyTriggerAction.sol';
import {ISimpleActions} from 'interfaces/actions-builders/ISimpleActions.sol';
import {ISimpleTransfers} from 'interfaces/actions-builders/ISimpleTransfers.sol';
import {ICanonGuardFactory} from 'interfaces/factories/ICanonGuardFactory.sol';
import {DeployCanonGuard} from 'script/DeployCanonGuard.s.sol';
import {AllowanceClaimorFactory} from 'src/contracts/factories/AllowanceClaimorFactory.sol';
import {CanonGuardFactory} from 'src/contracts/factories/CanonGuardFactory.sol';
import {CappedTokenTransfersHubFactory} from 'src/contracts/factories/CappedTokenTransfersHubFactory.sol';
import {ChangeSafeGuardActionFactory} from 'src/contracts/factories/ChangeSafeGuardActionFactory.sol';
import {EverclearTokenConversionFactory} from 'src/contracts/factories/EverclearTokenConversionFactory.sol';
import {OPxActionFactory} from 'src/contracts/factories/OPxActionFactory.sol';
import {PreApproveActionFactory} from 'src/contracts/factories/PreApproveActionFactory.sol';
import {SetEmergencyCallerActionFactory} from 'src/contracts/factories/SetEmergencyCallerActionFactory.sol';
import {SetEmergencyTriggerActionFactory} from 'src/contracts/factories/SetEmergencyTriggerActionFactory.sol';
import {SimpleActionsFactory} from 'src/contracts/factories/SimpleActionsFactory.sol';
import {SimpleTransfersFactory} from 'src/contracts/factories/SimpleTransfersFactory.sol';

contract UnitDeployCanonGuard is DeployCanonGuard, Test {
  ICanonGuardFactory internal _auxCanonGuardFactory;

  function setUp() public {
    // Deploy the CanonGuardFactory contract
    _auxCanonGuardFactory = ICanonGuardFactory(deployCode('CanonGuardFactory', abi.encode(MULTI_SEND_CALL_ONLY)));
  }

  function _computeCreate2Address(bytes memory _creationCode) private pure returns (address _address) {
    _address = vm.computeCreate2Address(SALT, keccak256(_creationCode));
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

    // it should match the deterministic address
    _assertFactoriesAddresses();

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

  function _assertFactoriesAddresses() private view {
    assertEq(
      address(canonGuardFactory),
      _computeCreate2Address(abi.encodePacked(type(CanonGuardFactory).creationCode, abi.encode(MULTI_SEND_CALL_ONLY)))
    );
    assertEq(address(allowanceClaimorFactory), _computeCreate2Address(type(AllowanceClaimorFactory).creationCode));
    assertEq(address(preApproveActionFactory), _computeCreate2Address(type(PreApproveActionFactory).creationCode));
    assertEq(
      address(cappedTokenTransfersHubFactory), _computeCreate2Address(type(CappedTokenTransfersHubFactory).creationCode)
    );
    assertEq(
      address(changeSafeGuardActionFactory), _computeCreate2Address(type(ChangeSafeGuardActionFactory).creationCode)
    );
    assertEq(
      address(setEmergencyCallerActionFactory),
      _computeCreate2Address(type(SetEmergencyCallerActionFactory).creationCode)
    );
    assertEq(
      address(setEmergencyTriggerActionFactory),
      _computeCreate2Address(type(SetEmergencyTriggerActionFactory).creationCode)
    );
    assertEq(address(simpleActionsFactory), _computeCreate2Address(type(SimpleActionsFactory).creationCode));
    assertEq(address(simpleTransfersFactory), _computeCreate2Address(type(SimpleTransfersFactory).creationCode));
  }

  function _assertCommonContracts() private {
    IAllowanceClaimor _auxAllowanceClaimor = IAllowanceClaimor(
      deployCode('AllowanceClaimor', abi.encode(DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_ADDRESS))
    );
    IPreApproveAction _auxPreApproveAction = IPreApproveAction(
      deployCode('PreApproveAction', abi.encode(DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_APPROVAL_DURATION))
    );
    // NOTE: doing this in order to match msg.sender when deploying the contract
    vm.prank(DEFAULT_SENDER);
    ICappedTokenTransfers _auxCappedTokenTransfers =
      ICappedTokenTransfers(deployCode('CappedTokenTransfers', abi.encode(DUMMY_ADDRESS, DUMMY_AMOUNT, DUMMY_ADDRESS)));
    IChangeSafeGuardAction _auxChangeSafeGuardAction =
      IChangeSafeGuardAction(deployCode('ChangeSafeGuardAction', abi.encode(DUMMY_ADDRESS, DUMMY_ADDRESS)));
    ISetEmergencyCallerAction _auxSetEmergencyCallerAction =
      ISetEmergencyCallerAction(deployCode('SetEmergencyCallerAction', abi.encode(DUMMY_ADDRESS, DUMMY_ADDRESS)));
    ISetEmergencyTriggerAction _auxSetEmergencyTriggerAction =
      ISetEmergencyTriggerAction(deployCode('SetEmergencyTriggerAction', abi.encode(DUMMY_ADDRESS, DUMMY_ADDRESS)));
    ISimpleActions _auxSimpleActions =
      ISimpleActions(deployCode('SimpleActions', abi.encode(DUMMY_ADDRESS, new ISimpleActions.SimpleAction[](0))));
    ISimpleTransfers _auxSimpleTransfers = ISimpleTransfers(
      deployCode('SimpleTransfers', abi.encode(DUMMY_ADDRESS, new ISimpleTransfers.TransferAction[](0)))
    );
    ICappedTokenTransfersHub _auxCappedTokenTransfersHub = ICappedTokenTransfersHub(
      deployCode(
        'CappedTokenTransfersHub',
        abi.encode(DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_ADDRESS, new address[](0), new uint256[](0), DUMMY_EPOCH_LENGTH)
      )
    );
    ICanonGuard _auxCanonGuard = ICanonGuard(
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
    IActionsBuilder _auxSetGuardAction = IActionsBuilder(deployCode('SetGuardAction'));
    IActionsBuilder _auxUnsetEmergencyModeAction = IActionsBuilder(deployCode('UnsetEmergencyModeAction'));

    assertEq(address(_allowanceClaimor).code, address(_auxAllowanceClaimor).code);
    assertEq(address(_preApproveAction).code, address(_auxPreApproveAction).code);
    assertEq(address(_cappedTokenTransfers).code, address(_auxCappedTokenTransfers).code);
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
