// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ActionTarget, BaseHandlers} from './BaseHandlers.sol';
import {CappedTokenTransfers} from 'contracts/actions-builders/CappedTokenTransfers.sol';
import {ICappedTokenTransfersHub} from 'interfaces/action-hubs/ICappedTokenTransfersHub.sol';

abstract contract HandlersCappedTokenTransfersHub is BaseHandlers {
  // Track created hubs for testing
  mapping(address => uint256) public hubTokenCaps;
  mapping(address => address) public hubTokens; // hub -> token address
  mapping(address token => mapping(uint256 amount => bool exists)) public actionBuilderExists;
  address[] public createdHubs;

  function handler_createNewActionBuilderFromHub(
    uint256 _approvalDuration,
    uint256 _amount,
    uint256 _capMultiplier
  ) public {
    _approvalDuration = bound(_approvalDuration, 1, 1000);
    _amount = bound(_amount, 1, 1_000_000);
    _capMultiplier = bound(_capMultiplier, 1, 5); // Cap will be 1x to 5x the amount

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

  function handler_queueCappedTokenTransfersFromHub(uint256 _approvalDuration, uint256 _amount) public {
    _approvalDuration = bound(_approvalDuration, 1, 1000);
    _amount = bound(_amount, 1, 1_000_000);

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
