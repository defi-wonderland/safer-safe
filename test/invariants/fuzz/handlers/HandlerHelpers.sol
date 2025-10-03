// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GhostState} from './GhostState.sol';

import {Safe} from '@safe-smart-account/Safe.sol';
import {CanonGuard} from 'contracts/CanonGuard.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';

/// @title HandlerHelpers
/// @notice Common helper functions for handlers to reduce code duplication
/// @dev Provides standardized patterns for approval, queuing, and error handling
abstract contract HandlerHelpers is GhostState {
  /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
  //////////////////////////////////////////////////////////////*/

  CanonGuard public canonGuard;
  Safe public safe;
  address[] public signers;

  /*//////////////////////////////////////////////////////////////
                            APPROVAL HELPERS
  //////////////////////////////////////////////////////////////*/

  /// @notice Try to approve an action builder or hub
  /// @dev Handles the common try-catch pattern for approvals
  /// @param _builder The action builder or hub to approve
  /// @param _duration The approval duration
  /// @return success Whether the approval succeeded
  function _tryApproveBuilder(address _builder, uint256 _duration) internal returns (bool success) {
    vm.prank(address(safe));
    try canonGuard.approveActionsBuilderOrHub(_builder, _duration) {
      _recordApproval(_builder);
      return true;
    } catch {
      // Approval failed - likely duration exceeds MAX_APPROVAL_DURATION
      assertGt(_duration, canonGuard.MAX_APPROVAL_DURATION());
      return false;
    }
  }

  /*//////////////////////////////////////////////////////////////
                            QUEUE HELPERS
  //////////////////////////////////////////////////////////////*/

  /// @notice Queue an action builder and record it in ghost state
  /// @dev Standardizes the queuing process across all handlers
  /// @param _builder The action builder to queue
  /// @param _type The type of action builder
  /// @param _signer The signer to use for queuing
  function _queueBuilder(address _builder, ActionsBuilderType _type, address _signer) internal {
    vm.prank(_signer);
    canonGuard.queueTransaction(_builder);

    bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(_builder);
    _recordHash(_safeTxHash, _builder, _type);
  }

  /*//////////////////////////////////////////////////////////////
                            ERROR HELPERS
  //////////////////////////////////////////////////////////////*/

  /// @notice Check if an error is a timing-related error
  /// @param _reason The error bytes from a catch block
  /// @return isTimingError True if the error is timing-related
  function _isTimingError(bytes memory _reason) internal pure virtual returns (bool isTimingError) {
    bytes4 selector = bytes4(_reason);
    return (
      selector == bytes4(keccak256('TransactionNotYetExecutable()'))
        || selector == bytes4(keccak256('NoTransactionQueued()')) || selector == bytes4(keccak256('TransactionExpired()'))
    );
  }

  /// @notice Assert that a timing error is correct
  /// @dev Validates that the timing error matches the actual state
  /// @param _reason The error bytes
  /// @param _actionsBuilder The action builder address
  function _assertTimingError(bytes memory _reason, address _actionsBuilder) internal view virtual {
    bytes4 errorSelector = bytes4(_reason);

    if (errorSelector == bytes4(keccak256('TransactionNotYetExecutable()'))) {
      (,, uint256 _executableAt,,) = canonGuard.transactionsInfo(_actionsBuilder);
      assertLt(block.timestamp, _executableAt, 'Transaction should not be executable yet');
    } else if (errorSelector == bytes4(keccak256('TransactionExpired()'))) {
      (,, uint256 _expiresAt,,) = canonGuard.transactionsInfo(_actionsBuilder);
      assertGe(block.timestamp, _expiresAt, 'Transaction should be expired');
    } else if (errorSelector == bytes4(keccak256('NoTransactionQueued()'))) {
      (,, uint256 _expiresAt,,) = canonGuard.transactionsInfo(_actionsBuilder);
      assertEq(_expiresAt, 0, 'Transaction should not exist');
    }
  }

  /// @notice Check if an error is an authorization error
  /// @param _reason The error bytes from a catch block
  /// @return isAuthError True if the error is authorization-related
  function _isAuthError(bytes memory _reason) internal pure returns (bool isAuthError) {
    bytes4 selector = bytes4(_reason);
    return (
      selector == bytes4(keccak256('CallerMustBeTransactionProposer()'))
        || selector == bytes4(keccak256('TransactionWithSignaturesCannotBeCancelled()'))
        || selector == bytes4(keccak256('Unauthorized(address,address)'))
    );
  }

  /*//////////////////////////////////////////////////////////////
                            BOUNDARY HELPERS
  //////////////////////////////////////////////////////////////*/

  /// @notice Get a random signer from the signers array
  /// @param _seed A random seed
  /// @return signer The selected signer address
  function _getRandomSigner(uint256 _seed) internal view returns (address signer) {
    return signers[_seed % signers.length];
  }

  /// @notice Get a random hash from the ghost state
  /// @param _seed A random seed
  /// @return hash The selected hash
  function _getRandomHash(uint256 _seed) internal view returns (bytes32 hash) {
    if (ghost_hashes.length == 0) return bytes32(0);
    return ghost_hashes[_seed % ghost_hashes.length];
  }

  /// @notice Get a random action builder from the ghost state
  /// @param _seed A random seed
  /// @return builder The selected action builder address
  function _getRandomBuilder(uint256 _seed) internal view returns (address builder) {
    bytes32 hash = _getRandomHash(_seed);
    if (hash == bytes32(0)) return address(0);
    return ghost_hashToActionsBuilder[hash];
  }
}
