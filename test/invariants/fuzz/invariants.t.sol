// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {HandlersTarget, Setup} from './Setup.t.sol';
import {ICappedTokenTransfersHub} from 'interfaces/action-hubs/ICappedTokenTransfersHub.sol';

contract Invariants is Setup {
  // Property: Cap limits are never exceeded in any hub
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

          // Cap should never be exceeded within an epoch
          assertLe(totalSpent, cap);
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

  function test_repro() public {}
}
