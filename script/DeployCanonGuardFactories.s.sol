// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Script} from 'forge-std/Script.sol';

import {CappedTokenTransfersHub} from 'contracts/action-hubs/CappedTokenTransfersHub.sol';
import {AllowanceClaimor} from 'contracts/actions-builders/AllowanceClaimor.sol';
import {ApproveAction} from 'contracts/actions-builders/ApproveAction.sol';
import {CappedTokenTransfers} from 'contracts/actions-builders/CappedTokenTransfers.sol';
import {ChangeSafeGuardAction} from 'contracts/actions-builders/ChangeSafeGuardAction.sol';
import {DisapproveAction} from 'contracts/actions-builders/DisapproveAction.sol';
import {EverclearTokenConversion} from 'contracts/actions-builders/EverclearTokenConversion.sol';
import {EverclearTokenStake} from 'contracts/actions-builders/EverclearTokenStake.sol';
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
import {DisapproveActionFactory} from 'contracts/factories/DisapproveActionFactory.sol';
import {EverclearTokenConversionFactory} from 'contracts/factories/EverclearTokenConversionFactory.sol';
import {EverclearTokenStakeFactory} from 'contracts/factories/EverclearTokenStakeFactory.sol';
import {OPxActionFactory} from 'contracts/factories/OPxActionFactory.sol';
import {SetEmergencyCallerActionFactory} from 'contracts/factories/SetEmergencyCallerActionFactory.sol';
import {SetEmergencyTriggerActionFactory} from 'contracts/factories/SetEmergencyTriggerActionFactory.sol';
import {SimpleActionsFactory} from 'contracts/factories/SimpleActionsFactory.sol';
import {SimpleTransfersFactory} from 'contracts/factories/SimpleTransfersFactory.sol';
import {UnsetEmergencyModeActionFactory} from 'contracts/factories/UnsetEmergencyModeActionFactory.sol';
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

contract DeployCanonGuardFactories is Constants, Script {
  // ~~~ ERRORS ~~~
  error UnsupportedChainId();

  // ~~~ FACTORIES ~~~
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

  // ~~~ DUMMY CONSTANTS ~~~
  address public constant DUMMY_ADDRESS = address(0);
  uint256 public constant DUMMY_APPROVAL_DURATION = 0;
  uint256 public constant DUMMY_AMOUNT = 0;
  uint256 public constant DUMMY_LOCK_TIME = 0;
  uint256 public constant DUMMY_EPOCH_LENGTH = 1;

  function deployCanonGuardFactories() public {
    vm.startBroadcast();

    if (block.chainid == ETHEREUM_MAINNET_CHAIN_ID) {
      _deployAllChainsFactories();
      _deployEthereumFactories();
      _deployAllChainsActions();
      _deployEthereumActions();
    } else if (block.chainid == OPTIMISM_MAINNET_CHAIN_ID) {
      _deployAllChainsFactories();
      _deployOptimismFactories();
      _deployAllChainsActions();
      _deployOptimismActions();
    } else {
      revert UnsupportedChainId();
    }

    vm.stopBroadcast();
  }

  function _deployAllChainsFactories() internal {
    // Needs to be first to match the value CANON_GUARD_FACTORY in Constants
    canonGuardFactory = new CanonGuardFactory(address(MULTI_SEND_CALL_ONLY));

    allowanceClaimorFactory = new AllowanceClaimorFactory();
    approveActionFactory = new ApproveActionFactory();
    cappedTokenTransfersHubFactory = new CappedTokenTransfersHubFactory();
    changeSafeGuardActionFactory = new ChangeSafeGuardActionFactory();
    disapproveActionFactory = new DisapproveActionFactory();
    setEmergencyCallerActionFactory = new SetEmergencyCallerActionFactory();
    setEmergencyTriggerActionFactory = new SetEmergencyTriggerActionFactory();
    simpleActionsFactory = new SimpleActionsFactory();
    simpleTransfersFactory = new SimpleTransfersFactory();
    unsetEmergencyModeActionFactory = new UnsetEmergencyModeActionFactory();
  }

  function _deployEthereumFactories() internal {
    everclearTokenConversionFactory = new EverclearTokenConversionFactory();
    everclearTokenStakeFactory = new EverclearTokenStakeFactory();
  }

  function _deployOptimismFactories() internal {
    opxActionFactory = new OPxActionFactory();
  }

  function _deployAllChainsActions() internal {
    new AllowanceClaimor(DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_ADDRESS);
    new ApproveAction(DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_APPROVAL_DURATION);
    new CappedTokenTransfers(DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_AMOUNT, DUMMY_ADDRESS, DUMMY_ADDRESS);
    new ChangeSafeGuardAction(DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_ADDRESS);
    new DisapproveAction(DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_ADDRESS);
    new SetEmergencyCallerAction(DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_ADDRESS);
    new SetEmergencyTriggerAction(DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_ADDRESS);
    new SimpleActions(DUMMY_ADDRESS, new SimpleActions.SimpleAction[](0));
    new SimpleTransfers(DUMMY_ADDRESS, new SimpleTransfers.TransferAction[](0));
    new UnsetEmergencyModeAction(DUMMY_ADDRESS, DUMMY_ADDRESS);
    new CappedTokenTransfersHub(
      DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_ADDRESS, new address[](0), new uint256[](0), DUMMY_EPOCH_LENGTH
    );
  }

  function _deployEthereumActions() internal {
    new EverclearTokenConversion(DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_ADDRESS);
    new EverclearTokenStake(
      DUMMY_ADDRESS,
      DUMMY_ADDRESS,
      DUMMY_ADDRESS,
      DUMMY_ADDRESS,
      DUMMY_ADDRESS,
      DUMMY_ADDRESS,
      DUMMY_ADDRESS,
      DUMMY_ADDRESS,
      DUMMY_LOCK_TIME
    );
  }

  function _deployOptimismActions() internal {
    new OPxAction(DUMMY_ADDRESS, DUMMY_ADDRESS, DUMMY_ADDRESS);
  }
}
