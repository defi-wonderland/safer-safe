// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {HandlersTarget, Setup} from './Setup.t.sol';
import {ICappedTokenTransfersHub} from 'interfaces/action-hubs/ICappedTokenTransfersHub.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';

contract Invariants is Setup {
  // Property: Cap limits are never exceeded in any hub (accounting for epoch boundaries)
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
          uint256 currentEpoch = ICappedTokenTransfersHub(hub).currentEpoch();
          uint256 epochLength = ICappedTokenTransfersHub(hub).EPOCH_LENGTH();
          uint256 startingTimestamp = ICappedTokenTransfersHub(hub).STARTING_TIMESTAMP();

          // Calculate the actual current epoch based on block.timestamp
          uint256 actualCurrentEpoch = (block.timestamp - startingTimestamp) / epochLength;

          // If we're in a new epoch (not yet updated), totalSpent should be from old epoch
          // Otherwise, totalSpent is for current epoch
          if (actualCurrentEpoch > currentEpoch) {
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

  // Ghost state consistency: hash vs action builder
  function invariant_sanity_ghostStateConsistency() public view {
    uint256 hashCount = handlersTarget.getGhostHashesLength();

    // Every hash should have a corresponding action builder
    for (uint256 i = 0; i < hashCount; i++) {
      bytes32 hash = handlersTarget.getGhostHash(i);
      address actionBuilder = handlersTarget.ghost_hashToActionsBuilder(hash);
      assertTrue(actionBuilder != address(0));
    }
  }

  // Property: Queued transactions only exist for approved action builders/hubs with valid approvals
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

  // Property: Queue and mapping are consistent
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

  function test_repro() public {
    vm.prank(0xB68691E947C62406642f9E7D358Ff17C36472326);
    HandlersTarget(0xc7183455a4C133Ae270771860664b6B7ec320bB1).handler_changeTxExpiryDelay(
      5_774_435_210_107_261_104_143_391_061_237_683_844_394_243_136_155_894_042_414_606_451_821_748_432_706
    );
    vm.prank(0xd4d4e13cEcdf9F6f7D90Ef62217b3eE5c1C02d04);
    HandlersTarget(0xc7183455a4C133Ae270771860664b6B7ec320bB1).handler_queueEverclearTokenStake(
      147_815_566_634_283_443_133_661_191_939_982_363_159, 2498
    );
    vm.prank(0x00000000000000000000000000000000000013c3);
    HandlersTarget(0xc7183455a4C133Ae270771860664b6B7ec320bB1).handler_warp(507_424_334_919_110_579_073);
    vm.prank(0x000000000000000000000000000000000000cF64);
    HandlersTarget(0xc7183455a4C133Ae270771860664b6B7ec320bB1).handler_approveHash(126_978, 11_682);
    vm.prank(0x0000000000000000000000000000000000013024);
    HandlersTarget(0xc7183455a4C133Ae270771860664b6B7ec320bB1).handler_approveHash(
      293_324_277_930_962, 633_632_081_283_941_399_851_427_520_594_466_435_457_560_454_162_167_326_458_474_924
    );
    vm.prank(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a);
    HandlersTarget(0xc7183455a4C133Ae270771860664b6B7ec320bB1).handler_approveHash(1540, 4410);
    vm.prank(0x000000000000000000000000000000000000Ec84);
    HandlersTarget(0xc7183455a4C133Ae270771860664b6B7ec320bB1).handler_executeTransaction(6_593_598_096_551);
  }
}
