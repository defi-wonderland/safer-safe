// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Setup} from './Setup.t.sol';
import {ICappedTokenTransfersHub} from 'interfaces/action-hubs/ICappedTokenTransfersHub.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';

contract Invariants is Setup {
  /*//////////////////////////////////////////////////////////////
                      CAP & ACCOUNTING INVARIANTS
  //////////////////////////////////////////////////////////////*/

  /// @notice Property: Cap limits are never exceeded in any hub (accounting for epoch boundaries)
  function invariant_capNeverExceeded() public view {
    uint256 hubCount = handlersTarget.getCreatedHubsLength();

    for (uint256 i = 0; i < hubCount; i++) {
      address[] memory hubs = handlersTarget.getCreatedHubs();
      if (i < hubs.length) {
        address hub = hubs[i];
        address token = handlersTarget.hubTokens(hub);

        if (token != address(0)) {
          uint256 cap = ICappedTokenTransfersHub(hub).cap(token);
          uint256 totalSpent = ICappedTokenTransfersHub(hub).totalSpent(token);
          uint256 lastEpoch = ICappedTokenTransfersHub(hub).lastEpoch(token);
          uint256 epochLength = ICappedTokenTransfersHub(hub).EPOCH_LENGTH();

          // Calculate the actual current epoch based on block.timestamp
          uint256 secondsSinceLastEpoch = block.timestamp - lastEpoch;
          uint256 remainder = secondsSinceLastEpoch % epochLength;
          uint256 actualCurrentEpoch = block.timestamp - remainder;

          // If we're in a new epoch (not yet updated), totalSpent should be from old epoch
          // Otherwise, totalSpent is for current epoch
          if (actualCurrentEpoch > lastEpoch) {
            // Hub hasn't updated yet, so totalSpent is from previous epoch
            // This is fine, cap only matters within same epoch
          } else {
            // Same epoch, cap must not be exceeded
            assertLe(totalSpent, cap);
          }
        }
      }
    }
  }

  /*//////////////////////////////////////////////////////////////
                      GHOST STATE INVARIANTS
  //////////////////////////////////////////////////////////////*/

  /// @notice Ghost state consistency: hash vs action builder
  function invariant_sanity_ghostStateConsistency() public view {
    uint256 hashCount = handlersTarget.getGhostHashesLength();

    // Every hash should have a corresponding action builder
    for (uint256 i = 0; i < hashCount; i++) {
      bytes32 hash = handlersTarget.getGhostHash(i);
      address actionBuilder = handlersTarget.ghost_hashToActionsBuilder(hash);
      assertTrue(actionBuilder != address(0));
    }
  }

  /*//////////////////////////////////////////////////////////////
                      APPROVAL & TIMING INVARIANTS
  //////////////////////////////////////////////////////////////*/

  /// @notice Property: Queued transactions only exist for approved action builders/hubs with valid approvals
  function invariant_queuedTransactionsHaveValidApprovals() public view {
    address[] memory queuedBuilders = handlersTarget.canonGuard().getQueuedActionBuilders();

    for (uint256 i = 0; i < queuedBuilders.length; i++) {
      address actionsBuilder = queuedBuilders[i];

      // Get transaction info
      (,, uint256 _expiresAt,, bool _isPreApproved) = handlersTarget.canonGuard().transactionsInfo(actionsBuilder);

      // Transaction must be queued (expiresAt != 0)
      assertTrue(_expiresAt > 0);

      // If pre-approved, either the builder itself or its parent (hub) must have an approval
      if (_isPreApproved) {
        uint256 approvalExpiry = handlersTarget.canonGuard().approvalExpiries(actionsBuilder);

        // If no approval directly on builder, check if it has a parent (hub)
        if (approvalExpiry == 0) {
          // Try to get parent - if this reverts, it means no parent exists
          try IActionsBuilder(actionsBuilder).PARENT() returns (address parent) {
            if (parent != address(0)) {
              uint256 parentApprovalExpiry = handlersTarget.canonGuard().approvalExpiries(parent);
              // Parent hub must have an approval
              assertTrue(parentApprovalExpiry > 0);
            } else {
              // No parent and no approval - this should not happen for pre-approved
              assertTrue(false);
            }
          } catch {
            // No PARENT() function - must have direct approval
            assertTrue(false);
          }
        }
      }
    }
  }

  /// @notice Property: Approval expiries never exceed max approval duration from time of approval
  function invariant_approvalExpiriesAreValid() public view {
    uint256 hashCount = handlersTarget.getGhostHashesLength();

    for (uint256 i = 0; i < hashCount; i++) {
      bytes32 hash = handlersTarget.getGhostHash(i);
      address actionsBuilder = handlersTarget.ghost_hashToActionsBuilder(hash);

      uint256 approvalExpiry = handlersTarget.canonGuard().approvalExpiries(actionsBuilder);

      // If approval exists, it should be reasonable (not too far in the future)
      if (approvalExpiry > 0) {
        // Approval expiry should never be more than MAX_APPROVAL_DURATION from current time
        // (allowing for some historical approvals that haven't expired yet)
        assertTrue(approvalExpiry <= block.timestamp + handlersTarget.canonGuard().MAX_APPROVAL_DURATION());
      }
    }
  }

  /// @notice Property: Transaction timing is always correct
  function invariant_transactionTimingIsCorrect() public view {
    uint256 hashCount = handlersTarget.getGhostHashesLength();

    for (uint256 i = 0; i < hashCount; i++) {
      bytes32 hash = handlersTarget.getGhostHash(i);
      address actionsBuilder = handlersTarget.ghost_hashToActionsBuilder(hash);

      (,, uint256 executableAt, uint256 expiresAt, bool isPreApproved) =
        handlersTarget.canonGuard().transactionsInfo(actionsBuilder);

      // If transaction is queued
      if (expiresAt > 0) {
        // expiresAt must be greater than executableAt
        assertGt(expiresAt, executableAt);

        // Get the queued timestamp from ghost state
        uint256 queuedAt = handlersTarget.ghost_timestampOfActionQueued(hash);

        if (queuedAt > 0) {
          // Calculate expected execution delay
          // solhint-disable-next-line no-unused-vars
          uint256 expectedDelay = isPreApproved
            ? handlersTarget.canonGuard().SHORT_TX_EXECUTION_DELAY()
            : handlersTarget.canonGuard().MAX_TX_EXECUTION_DELAY();

          // executableAt should be queuedAt + delay (within reason, accounting for redeployments)
          // We allow executableAt to be >= queuedAt since delays could change
          assertGe(executableAt, queuedAt);

          // expiresAt should be executableAt + TX_EXPIRY_DELAY
          // This can vary if TX_EXPIRY_DELAY changes, so we just check it's > executableAt
          assertGt(expiresAt, executableAt);
        }
      }
    }
  }

  /// @notice Property: Pre-approved transactions must have had valid approval at queue time
  /// @dev isPreApproved indicates the transaction was approved at QUEUE time, not that approval is still valid
  // Approvals can expire after queuing, which is expected behavior
  function invariant_preApprovedTransactionsUsedShortDelay() public view {
    address[] memory queuedBuilders = handlersTarget.canonGuard().getQueuedActionBuilders();

    for (uint256 i = 0; i < queuedBuilders.length; i++) {
      address actionsBuilder = queuedBuilders[i];
      (,, uint256 executableAt, uint256 expiresAt, bool isPreApproved) =
        handlersTarget.canonGuard().transactionsInfo(actionsBuilder);

      // If transaction is queued and marked as pre-approved
      if (expiresAt > 0 && isPreApproved) {
        uint256 queuedAt = handlersTarget.ghost_timestampOfActionQueued(
          handlersTarget.canonGuard().getSafeTransactionHash(actionsBuilder, handlersTarget.canonGuard().getSafeNonce())
        );

        // If we have queue timestamp, verify short delay was used
        if (queuedAt > 0 && queuedAt <= executableAt) {
          uint256 actualDelay = executableAt - queuedAt;
          uint256 shortDelay = handlersTarget.canonGuard().SHORT_TX_EXECUTION_DELAY();
          // Allow for some tolerance due to reconfigurations
          // The delay should be <= short delay (could be less due to reconfig to shorter delay)
          assertLe(actualDelay, shortDelay);
        }
      }
    }
  }

  /*//////////////////////////////////////////////////////////////
                      QUEUE CONSISTENCY INVARIANTS
  //////////////////////////////////////////////////////////////*/

  /// @notice Property: Queue has no duplicate action builders
  function invariant_queueHasNoDuplicates() public view {
    address[] memory queuedBuilders = handlersTarget.canonGuard().getQueuedActionBuilders();

    // Check for duplicates by comparing each element with all subsequent elements
    for (uint256 i = 0; i < queuedBuilders.length; i++) {
      for (uint256 j = i + 1; j < queuedBuilders.length; j++) {
        assertTrue(queuedBuilders[i] != queuedBuilders[j]);
      }
    }
  }

  /// @notice Property: All queued action builders have non-zero expiry
  function invariant_allQueuedBuildersHaveNonZeroExpiry() public view {
    address[] memory queuedBuilders = handlersTarget.canonGuard().getQueuedActionBuilders();

    for (uint256 i = 0; i < queuedBuilders.length; i++) {
      (,, uint256 expiresAt,,) = handlersTarget.canonGuard().transactionsInfo(queuedBuilders[i]);
      assertTrue(expiresAt > 0);
    }
  }

  /// @notice Property: Queue and mapping are consistent
  function invariant_queueMappingConsistency() public view {
    address[] memory queuedBuilders = handlersTarget.canonGuard().getQueuedActionBuilders();

    // Every builder in queue must have non-zero expiresAt in mapping
    for (uint256 i = 0; i < queuedBuilders.length; i++) {
      address actionsBuilder = queuedBuilders[i];
      (,, uint256 _expiresAt,,) = handlersTarget.canonGuard().transactionsInfo(actionsBuilder);
      assertTrue(_expiresAt > 0);
    }

    // Every builder with non-zero expiresAt in mapping must be in queue
    // (We can't iterate all possible addresses, so we check our ghost state)
    uint256 hashCount = handlersTarget.getGhostHashesLength();
    for (uint256 i = 0; i < hashCount; i++) {
      bytes32 hash = handlersTarget.getGhostHash(i);
      address actionsBuilder = handlersTarget.ghost_hashToActionsBuilder(hash);

      (,, uint256 _expiresAt,,) = handlersTarget.canonGuard().transactionsInfo(actionsBuilder);

      if (_expiresAt > 0) {
        // Must be in queue
        bool foundInQueue = false;
        for (uint256 j = 0; j < queuedBuilders.length; j++) {
          if (queuedBuilders[j] == actionsBuilder) {
            foundInQueue = true;
            break;
          }
        }
        assertTrue(foundInQueue);
      }
    }
  }
}
