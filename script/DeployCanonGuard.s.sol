// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {CappedTokenTransfersHub} from 'contracts/action-hubs/CappedTokenTransfersHub.sol';
import {AllowanceClaimor} from 'contracts/actions-builders/AllowanceClaimor.sol';
import {CappedTokenTransfers} from 'contracts/actions-builders/CappedTokenTransfers.sol';
import {ChangeSafeGuardAction} from 'contracts/actions-builders/ChangeSafeGuardAction.sol';
import {EverclearTokenConversion} from 'contracts/actions-builders/EverclearTokenConversion.sol';
import {OPxAction} from 'contracts/actions-builders/OPxAction.sol';
import {PreApproveAction} from 'contracts/actions-builders/PreApproveAction.sol';
import {SetEmergencyCallerAction} from 'contracts/actions-builders/SetEmergencyCallerAction.sol';
import {SetEmergencyTriggerAction} from 'contracts/actions-builders/SetEmergencyTriggerAction.sol';
import {SimpleActions} from 'contracts/actions-builders/SimpleActions.sol';
import {SimpleTransfers} from 'contracts/actions-builders/SimpleTransfers.sol';
import {UnsetEmergencyModeAction} from 'contracts/actions-builders/UnsetEmergencyModeAction.sol';
import {AllowanceClaimorFactory} from 'contracts/factories/AllowanceClaimorFactory.sol';
import {CanonGuardFactory} from 'contracts/factories/CanonGuardFactory.sol';
import {CappedTokenTransfersHubFactory} from 'contracts/factories/CappedTokenTransfersHubFactory.sol';
import {ChangeSafeGuardActionFactory} from 'contracts/factories/ChangeSafeGuardActionFactory.sol';
import {EverclearTokenConversionFactory} from 'contracts/factories/EverclearTokenConversionFactory.sol';
import {OPxActionFactory} from 'contracts/factories/OPxActionFactory.sol';
import {PreApproveActionFactory} from 'contracts/factories/PreApproveActionFactory.sol';
import {SetEmergencyCallerActionFactory} from 'contracts/factories/SetEmergencyCallerActionFactory.sol';
import {SetEmergencyTriggerActionFactory} from 'contracts/factories/SetEmergencyTriggerActionFactory.sol';
import {SimpleActionsFactory} from 'contracts/factories/SimpleActionsFactory.sol';
import {SimpleTransfersFactory} from 'contracts/factories/SimpleTransfersFactory.sol';
import {Script} from 'forge-std/Script.sol';
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
import {IAllowanceClaimorFactory} from 'interfaces/factories/IAllowanceClaimorFactory.sol';
import {ICanonGuardFactory} from 'interfaces/factories/ICanonGuardFactory.sol';
import {ICappedTokenTransfersHubFactory} from 'interfaces/factories/ICappedTokenTransfersHubFactory.sol';
import {IChangeSafeGuardActionFactory} from 'interfaces/factories/IChangeSafeGuardActionFactory.sol';
import {IEverclearTokenConversionFactory} from 'interfaces/factories/IEverclearTokenConversionFactory.sol';
import {IOPxActionFactory} from 'interfaces/factories/IOPxActionFactory.sol';
import {IPreApproveActionFactory} from 'interfaces/factories/IPreApproveActionFactory.sol';
import {ISetEmergencyCallerActionFactory} from 'interfaces/factories/ISetEmergencyCallerActionFactory.sol';
import {ISetEmergencyTriggerActionFactory} from 'interfaces/factories/ISetEmergencyTriggerActionFactory.sol';
import {ISimpleActionsFactory} from 'interfaces/factories/ISimpleActionsFactory.sol';
import {ISimpleTransfersFactory} from 'interfaces/factories/ISimpleTransfersFactory.sol';
import {Constants} from 'script/Constants.sol';
import {CanonGuard} from 'src/contracts/CanonGuard.sol';
import {SetGuardAction} from 'src/contracts/actions-builders/SetGuardAction.sol';

/**
 * @title DeployCanonGuard
 * @notice Script that deploys the Factories and Contracts based on values in Constants.sol
 * @notice Contracts are manually deployed so they get verified. This would automatically verify any contract created
 * by the factories.
 */
// solhint-disable max-states-count
contract DeployCanonGuard is Constants, Script {
  // ~~~ ERRORS ~~~
  error UnsupportedChainId();

  // ~~~ FACTORIES ~~~
  IAllowanceClaimorFactory public allowanceClaimorFactory;
  IPreApproveActionFactory public preApproveActionFactory;
  ICanonGuardFactory public canonGuardFactory;
  ICappedTokenTransfersHubFactory public cappedTokenTransfersHubFactory;
  IChangeSafeGuardActionFactory public changeSafeGuardActionFactory;
  IEverclearTokenConversionFactory public everclearTokenConversionFactory;
  IOPxActionFactory public opxActionFactory;
  ISetEmergencyCallerActionFactory public setEmergencyCallerActionFactory;
  ISetEmergencyTriggerActionFactory public setEmergencyTriggerActionFactory;
  ISimpleActionsFactory public simpleActionsFactory;
  ISimpleTransfersFactory public simpleTransfersFactory;

  // ~~~ DUMMY CONTRACTS ~~~
  IAllowanceClaimor internal _allowanceClaimor;
  IPreApproveAction internal _preApproveAction;
  ICappedTokenTransfers internal _cappedTokenTransfers;
  IChangeSafeGuardAction internal _changeSafeGuardAction;
  ISetEmergencyCallerAction internal _setEmergencyCallerAction;
  ISetEmergencyTriggerAction internal _setEmergencyTriggerAction;
  ISimpleActions internal _simpleActions;
  ISimpleTransfers internal _simpleTransfers;
  ICappedTokenTransfersHub internal _cappedTokenTransfersHub;
  ICanonGuard internal _canonGuard;

  // ~~~ ACTIONS BUILDERS ~~~
  IActionsBuilder public setGuardAction;
  IActionsBuilder public unsetEmergencyModeAction;

  // ~~~ DUMMY CONSTANTS ~~~
  address public constant DUMMY_ADDRESS = address(1);
  uint256 public constant DUMMY_APPROVAL_DURATION = 0;
  uint256 public constant DUMMY_AMOUNT = 0;
  uint256 public constant DUMMY_LOCK_TIME = 0;
  uint256 public constant DUMMY_EPOCH_LENGTH = 1;
  uint256 public constant DUMMY_DELAY = 2 days;

  // ~~~ CREATE2 SALT ~~~
  bytes32 public constant SALT = keccak256('canon-guard');

  function run() public {
    vm.startBroadcast();

    _deployAllChainsFactories();
    _deployAllChainsContracts();

    if (block.chainid == ETHEREUM_MAINNET_CHAIN_ID) {
      _deployEthereumFactories();
      _deployEthereumContracts();
    } else if (block.chainid == OPTIMISM_MAINNET_CHAIN_ID) {
      _deployOptimismFactories();
      _deployOptimismContracts();
    }

    vm.stopBroadcast();
  }

  function _deployAllChainsFactories() internal {
    canonGuardFactory = new CanonGuardFactory{salt: SALT}(address(MULTI_SEND_CALL_ONLY));
    allowanceClaimorFactory = new AllowanceClaimorFactory{salt: SALT}();
    preApproveActionFactory = new PreApproveActionFactory{salt: SALT}();
    cappedTokenTransfersHubFactory = new CappedTokenTransfersHubFactory{salt: SALT}();
    changeSafeGuardActionFactory = new ChangeSafeGuardActionFactory{salt: SALT}();
    setEmergencyCallerActionFactory = new SetEmergencyCallerActionFactory{salt: SALT}();
    setEmergencyTriggerActionFactory = new SetEmergencyTriggerActionFactory{salt: SALT}();
    simpleActionsFactory = new SimpleActionsFactory{salt: SALT}();
    simpleTransfersFactory = new SimpleTransfersFactory{salt: SALT}();
  }

  function _deployEthereumFactories() internal {
    everclearTokenConversionFactory = new EverclearTokenConversionFactory();
  }

  function _deployOptimismFactories() internal {
    opxActionFactory = new OPxActionFactory();
  }

  function _deployAllChainsContracts() internal {
    _allowanceClaimor = IAllowanceClaimor(address(new AllowanceClaimor(DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_ADDRESS)));
    _preApproveAction = IPreApproveAction(address(new PreApproveAction(DUMMY_ADDRESS, DUMMY_APPROVAL_DURATION)));
    _cappedTokenTransfers =
      ICappedTokenTransfers(address(new CappedTokenTransfers(DUMMY_ADDRESS, DUMMY_AMOUNT, DUMMY_ADDRESS)));
    _changeSafeGuardAction = IChangeSafeGuardAction(address(new ChangeSafeGuardAction(DUMMY_ADDRESS)));
    _setEmergencyCallerAction = ISetEmergencyCallerAction(address(new SetEmergencyCallerAction(DUMMY_ADDRESS)));
    _setEmergencyTriggerAction = ISetEmergencyTriggerAction(address(new SetEmergencyTriggerAction(DUMMY_ADDRESS)));
    _simpleActions = ISimpleActions(address(new SimpleActions(new SimpleActions.SimpleAction[](0))));
    _simpleTransfers = ISimpleTransfers(address(new SimpleTransfers(new SimpleTransfers.TransferAction[](0))));
    _cappedTokenTransfersHub = ICappedTokenTransfersHub(
      address(
        new CappedTokenTransfersHub(
          DUMMY_ADDRESS, DUMMY_ADDRESS, new address[](0), new uint256[](0), DUMMY_EPOCH_LENGTH
        )
      )
    );
    _canonGuard = ICanonGuard(
      address(
        new CanonGuard(
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
    setGuardAction = IActionsBuilder(address(new SetGuardAction()));
    unsetEmergencyModeAction = IActionsBuilder(address(new UnsetEmergencyModeAction()));
  }

  function _deployEthereumContracts() internal {
    new EverclearTokenConversion(DUMMY_ADDRESS, DUMMY_ADDRESS);
  }

  function _deployOptimismContracts() internal {
    new OPxAction(DUMMY_ADDRESS);
  }
}
