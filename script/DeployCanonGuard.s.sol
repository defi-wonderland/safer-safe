// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {CappedTokenTransfersHub} from 'contracts/action-hubs/CappedTokenTransfersHub.sol';
import {AllowanceClaimor} from 'contracts/actions-builders/AllowanceClaimor.sol';
import {ApproveAction} from 'contracts/actions-builders/ApproveAction.sol';
import {CappedTokenTransfers} from 'contracts/actions-builders/CappedTokenTransfers.sol';
import {ChangeSafeGuardAction} from 'contracts/actions-builders/ChangeSafeGuardAction.sol';
import {EverclearTokenConversion} from 'contracts/actions-builders/EverclearTokenConversion.sol';
import {OPxAction} from 'contracts/actions-builders/OPxAction.sol';
import {SetEmergencyCallerAction} from 'contracts/actions-builders/SetEmergencyCallerAction.sol';
import {SetEmergencyTriggerAction} from 'contracts/actions-builders/SetEmergencyTriggerAction.sol';
import {SimpleActions} from 'contracts/actions-builders/SimpleActions.sol';
import {SimpleTransfers} from 'contracts/actions-builders/SimpleTransfers.sol';
import {UnsetEmergencyModeAction} from 'contracts/actions-builders/UnsetEmergencyModeAction.sol';
import {AllowanceClaimorFactory} from 'contracts/factories/AllowanceClaimorFactory.sol';
import {ApproveActionFactory} from 'contracts/factories/ApproveActionFactory.sol';
import {CanonGuardFactory} from 'contracts/factories/CanonGuardFactory.sol';
import {CappedTokenTransfersHubFactory} from 'contracts/factories/CappedTokenTransfersHubFactory.sol';
import {ChangeSafeGuardActionFactory} from 'contracts/factories/ChangeSafeGuardActionFactory.sol';
import {EverclearTokenConversionFactory} from 'contracts/factories/EverclearTokenConversionFactory.sol';
import {OPxActionFactory} from 'contracts/factories/OPxActionFactory.sol';
import {SetEmergencyCallerActionFactory} from 'contracts/factories/SetEmergencyCallerActionFactory.sol';
import {SetEmergencyTriggerActionFactory} from 'contracts/factories/SetEmergencyTriggerActionFactory.sol';
import {SimpleActionsFactory} from 'contracts/factories/SimpleActionsFactory.sol';
import {SimpleTransfersFactory} from 'contracts/factories/SimpleTransfersFactory.sol';
import {Script} from 'forge-std/Script.sol';
import {ICanonGuard} from 'interfaces/ICanonGuard.sol';
import {IAllowanceClaimorFactory} from 'interfaces/factories/IAllowanceClaimorFactory.sol';
import {IApproveActionFactory} from 'interfaces/factories/IApproveActionFactory.sol';
import {ICanonGuardFactory} from 'interfaces/factories/ICanonGuardFactory.sol';
import {ICappedTokenTransfersHubFactory} from 'interfaces/factories/ICappedTokenTransfersHubFactory.sol';
import {IChangeSafeGuardActionFactory} from 'interfaces/factories/IChangeSafeGuardActionFactory.sol';
import {IEverclearTokenConversionFactory} from 'interfaces/factories/IEverclearTokenConversionFactory.sol';
import {IOPxActionFactory} from 'interfaces/factories/IOPxActionFactory.sol';
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

  // ~~~ CANON GUARD ~~~
  ICanonGuard public canonGuard;

  // ~~~ FACTORIES ~~~
  IAllowanceClaimorFactory public allowanceClaimorFactory;
  IApproveActionFactory public approveActionFactory;
  ICanonGuardFactory public canonGuardFactory;
  ICappedTokenTransfersHubFactory public cappedTokenTransfersHubFactory;
  IChangeSafeGuardActionFactory public changeSafeGuardActionFactory;
  IEverclearTokenConversionFactory public everclearTokenConversionFactory;
  IOPxActionFactory public opxActionFactory;
  ISetEmergencyCallerActionFactory public setEmergencyCallerActionFactory;
  ISetEmergencyTriggerActionFactory public setEmergencyTriggerActionFactory;
  ISimpleActionsFactory public simpleActionsFactory;
  ISimpleTransfersFactory public simpleTransfersFactory;

  // ~~~ ACTIONS BUILDERS ~~~
  SetGuardAction public setGuardAction;
  UnsetEmergencyModeAction public unsetEmergencyModeAction;

  // ~~~ DUMMY CONSTANTS ~~~
  address public constant DUMMY_ADDRESS = address(1);
  uint256 public constant DUMMY_APPROVAL_DURATION = 0;
  uint256 public constant DUMMY_AMOUNT = 0;
  uint256 public constant DUMMY_LOCK_TIME = 0;
  uint256 public constant DUMMY_EPOCH_LENGTH = 1;
  uint256 public constant DUMMY_DELAY = 2 days;

  function run() public {
    vm.startBroadcast();

    _deployAllChainsFactories();
    _deployAllChainsContracts();

    _deployCanonGuard();

    if (block.chainid == ETHEREUM_MAINNET_CHAIN_ID) {
      _deployEthereumFactories();
      _deployEthereumContracts();
    } else if (block.chainid == OPTIMISM_MAINNET_CHAIN_ID) {
      _deployOptimismFactories();
      _deployOptimismContracts();
    }

    vm.stopBroadcast();
  }

  function _deployCanonGuard() internal {
    // Deploy the CanonGuard contract
    canonGuard = ICanonGuard(
      canonGuardFactory.createCanonGuard(
        address(SAFE_PROXY),
        SHORT_TX_EXECUTION_DELAY,
        LONG_TX_EXECUTION_DELAY,
        TX_EXPIRY_DELAY,
        MAX_APPROVAL_DURATION,
        EMERGENCY_TRIGGER,
        EMERGENCY_CALLER
      )
    );
  }

  function _deployAllChainsFactories() internal {
    canonGuardFactory = new CanonGuardFactory(address(MULTI_SEND_CALL_ONLY));
    allowanceClaimorFactory = new AllowanceClaimorFactory();
    approveActionFactory = new ApproveActionFactory();
    cappedTokenTransfersHubFactory = new CappedTokenTransfersHubFactory();
    changeSafeGuardActionFactory = new ChangeSafeGuardActionFactory();
    setEmergencyCallerActionFactory = new SetEmergencyCallerActionFactory();
    setEmergencyTriggerActionFactory = new SetEmergencyTriggerActionFactory();
    simpleActionsFactory = new SimpleActionsFactory();
    simpleTransfersFactory = new SimpleTransfersFactory();
  }

  function _deployEthereumFactories() internal {
    everclearTokenConversionFactory = new EverclearTokenConversionFactory();
  }

  function _deployOptimismFactories() internal {
    opxActionFactory = new OPxActionFactory();
  }

  function _deployAllChainsContracts() internal {
    new AllowanceClaimor(DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_ADDRESS);
    new ApproveAction(DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_APPROVAL_DURATION);
    new CappedTokenTransfers(DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_AMOUNT, DUMMY_ADDRESS, DUMMY_ADDRESS);
    new ChangeSafeGuardAction(DUMMY_ADDRESS, DUMMY_ADDRESS);
    new SetEmergencyCallerAction(DUMMY_ADDRESS, DUMMY_ADDRESS);
    new SetEmergencyTriggerAction(DUMMY_ADDRESS, DUMMY_ADDRESS);
    new SimpleActions(DUMMY_ADDRESS, new SimpleActions.SimpleAction[](0));
    new SimpleTransfers(DUMMY_ADDRESS, new SimpleTransfers.TransferAction[](0));
    new CappedTokenTransfersHub(
      DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_ADDRESS, new address[](0), new uint256[](0), DUMMY_EPOCH_LENGTH
    );
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
    );
    setGuardAction = new SetGuardAction();
    unsetEmergencyModeAction = new UnsetEmergencyModeAction();
  }

  function _deployEthereumContracts() internal {
    new EverclearTokenConversion(DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_ADDRESS);
  }

  function _deployOptimismContracts() internal {
    new OPxAction(DUMMY_ADDRESS, DUMMY_ADDRESS);
  }
}
