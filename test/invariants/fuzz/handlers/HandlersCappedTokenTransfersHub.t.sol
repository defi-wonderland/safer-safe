// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {BaseHandlers} from './BaseHandlers.sol';
import {ICappedTokenTransfersHub} from 'interfaces/action-hubs/ICappedTokenTransfersHub.sol';

/// @title HandlersCappedTokenTransfersHub
/// @notice Handler for CappedTokenTransfersHub and its child action builders
/// @dev Tests invariants related to spending caps and epoch boundaries
abstract contract HandlersCappedTokenTransfersHub is BaseHandlers {
  /*//////////////////////////////////////////////////////////////
                            STATE TRACKING
  //////////////////////////////////////////////////////////////*/

  // Track created hubs for testing
  mapping(address hub => uint256 cap) public hubTokenCaps;
  mapping(address hub => address token) public hubTokens;
  mapping(address token => mapping(uint256 amount => bool exists)) public actionBuilderExists;
  address[] public createdHubs;

  /*//////////////////////////////////////////////////////////////
                            HANDLERS
  //////////////////////////////////////////////////////////////*/

  /// @notice Create a new hub with token cap and approve it
  /// @dev Tests hub creation and approval process
  /// @param _approvalDuration Duration of approval for the hub
  /// @param _amount Base amount for cap calculation
  /// @param _capMultiplier Multiplier for the cap (1x to 5x the amount)
  function handler_createNewActionBuilderFromHub(
    uint256 _approvalDuration,
    uint256 _amount,
    uint256 _capMultiplier
  ) public {
    _amount = bound(_amount, _MIN_AMOUNT, _MAX_AMOUNT);
    _capMultiplier = bound(_capMultiplier, _MIN_CAP_MULTIPLIER, _MAX_CAP_MULTIPLIER);

    address[] memory tokens = new address[](1);
    tokens[0] = address(actionTarget);
    uint256[] memory caps = new uint256[](1);
    caps[0] = _amount * _capMultiplier;

    address hub = cappedTokenTransfersHubFactory.createCappedTokenTransfersHub(
      address(safe), // safe
      address(signers[0]), // recipient
      tokens, // tokens
      caps, // caps
      1 days // epoch length
    );

    vm.prank(address(safe));
    try canonGuard.approveActionsBuilderOrHub(hub, _approvalDuration) {
      createdHubs.push(hub);
      hubTokenCaps[hub] = caps[0];
      hubTokens[hub] = address(actionTarget);
      ghost_approvedActionsBuilder[hub] = true;
    } catch {
      assertGt(_approvalDuration, canonGuard.MAX_APPROVAL_DURATION());
    }
  }

  /// @notice Queue a CappedTokenTransfers action builder from an existing hub
  /// @dev Tests child action builder creation and queuing from approved hubs
  /// @param _approvalDuration Duration of approval (not used directly, for consistency)
  /// @param _amount Amount for the transfer (also used as hub selector seed)
  // solhint-disable-next-line no-unused-vars
  function handler_queueCappedTokenTransfersFromHub(uint256 _approvalDuration, uint256 _amount) public {
    _amount = bound(_amount, _MIN_AMOUNT, _MAX_AMOUNT);

    if (createdHubs.length == 0) return;

    address hub = createdHubs[_amount % createdHubs.length];

    vm.prank(signers[0]);
    try ICappedTokenTransfersHub(hub).createNewActionsBuilder(address(actionTarget), _amount) returns (
      address actionsBuilder
    ) {
      vm.prank(signers[0]);
      canonGuard.queueTransaction(actionsBuilder);

      bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(actionsBuilder);

      ghost_hashToActionsBuilder[_safeTxHash] = actionsBuilder;
      ghost_hashes.push(_safeTxHash);
      ghost_timestampOfActionQueued[_safeTxHash] = block.timestamp;
      ghost_actionsBuilderType[actionsBuilder] = ActionsBuilderType.CAPPED_TOKEN_TRANSFERS_HUB;
      actionBuilderExists[address(actionTarget)][_amount] = true;
    } catch (bytes memory _reason) {
      // Another action builder for the same token + amount aldready exists (create collision)
      assert(
        actionBuilderExists[address(actionTarget)][_amount]
          && bytes4(_reason) == bytes4(keccak256('DeploymentFailed()'))
      );
    }
  }
}
