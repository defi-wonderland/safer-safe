// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';

/// @title GhostState
/// @notice Centralized ghost state tracking for invariant tests
/// @dev This contract maintains shadow state to track system behavior across handler calls
abstract contract GhostState is Test {
  /*//////////////////////////////////////////////////////////////
                            TYPE DEFINITIONS
  //////////////////////////////////////////////////////////////*/

  enum ActionsBuilderType {
    ALLOWANCE_CLAIMOR,
    CAPPED_TOKEN_TRANSFERS_HUB,
    EVERCLEAR_TOKEN_CONVERSION,
    EVERCLEAR_TOKEN_STAKE,
    OPX_ACTION,
    SIMPLE_ACTIONS,
    SIMPLE_TRANSFERS
  }

  /*//////////////////////////////////////////////////////////////
                            CORE TRACKING
  //////////////////////////////////////////////////////////////*/

  /// @notice Maps transaction hash to its corresponding action builder
  mapping(bytes32 hash => address builder) public ghost_hashToActionsBuilder;

  /// @notice Array of all transaction hashes that have been created
  bytes32[] public ghost_hashes;

  /// @notice Maps transaction hash to the timestamp when it was queued
  mapping(bytes32 hash => uint256 timestamp) public ghost_timestampOfActionQueued;

  /// @notice Maps action builder address to whether it's been approved
  mapping(address builder => bool approved) public ghost_approvedActionsBuilder;

  /// @notice Maps action builder address to its type
  mapping(address builder => ActionsBuilderType builderType) public ghost_actionsBuilderType;

  /// @notice Maps action builder to timestamp when approval was granted
  mapping(address builder => uint256 timestamp) public ghost_approvalTimestamp;

  /*//////////////////////////////////////////////////////////////
                        EMERGENCY MODE TRACKING
  //////////////////////////////////////////////////////////////*/

  /// @notice Tracks if emergency mode was ever activated
  bool public ghost_wasEmergencyModeEverSet;

  /// @notice Timestamp when emergency mode was first set (0 if never set)
  uint256 public ghost_emergencyModeSetTimestamp;

  /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /// @notice Record a new transaction hash with its associated builder
  /// @param _hash The transaction hash
  /// @param _builder The action builder address
  /// @param _type The type of action builder
  function _recordHash(bytes32 _hash, address _builder, ActionsBuilderType _type) internal {
    ghost_hashToActionsBuilder[_hash] = _builder;
    ghost_hashes.push(_hash);
    ghost_timestampOfActionQueued[_hash] = block.timestamp;
    ghost_actionsBuilderType[_builder] = _type;
  }

  /// @notice Record an approval
  /// @param _builder The action builder or hub being approved
  function _recordApproval(address _builder) internal {
    ghost_approvedActionsBuilder[_builder] = true;
    ghost_approvalTimestamp[_builder] = block.timestamp;
  }

  /// @notice Record emergency mode activation
  function _recordEmergencyMode() internal {
    if (!ghost_wasEmergencyModeEverSet) {
      ghost_wasEmergencyModeEverSet = true;
      ghost_emergencyModeSetTimestamp = block.timestamp;
    }
  }

  /*//////////////////////////////////////////////////////////////
                            GETTER FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /// @notice Get the total number of hashes recorded
  function getGhostHashesLength() public view virtual returns (uint256) {
    return ghost_hashes.length;
  }

  /// @notice Get a specific hash by index
  /// @param _index The index in the ghost_hashes array
  function getGhostHash(uint256 _index) public view virtual returns (bytes32) {
    return ghost_hashes[_index];
  }
}
