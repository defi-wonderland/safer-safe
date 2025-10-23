// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ActionTarget, BaseHandlers, CanonGuard, CanonGuardFactory, Safe} from './BaseHandlers.sol';

/// @title HandlersCanonGuard
/// @notice Handlers for CanonGuard and Safe interactions
/// @dev Tests core guard functionality, transaction lifecycle, and emergency mode
abstract contract HandlersCanonGuard is BaseHandlers {
  /*//////////////////////////////////////////////////////////////
                            APPROVAL HANDLERS
  //////////////////////////////////////////////////////////////*/

  /// @notice Approve an actions builder or hub
  /// @dev Tests approval expiry and duration validation
  /// @param _seed Random seed for selecting an action builder
  /// @param _approvalDuration Duration of approval (bounded to MAX_APPROVAL_DURATION)
  function handler_approveActionsBuilder(uint256 _seed, uint256 _approvalDuration) public {
    _approvalDuration = bound(_approvalDuration, 1, 10_000);

    if (ghost_hashes.length == 0) return;
    bytes32 _hash = ghost_hashes[_seed % ghost_hashes.length];

    address _actionsBuilder = ghost_hashToActionsBuilder[_hash];

    vm.prank(address(safe));
    try canonGuard.approveActionsBuilderOrHub(_actionsBuilder, _approvalDuration) {
      ghost_approvedActionsBuilder[_actionsBuilder] = true;
    } catch {
      assertGt(_approvalDuration, canonGuard.MAX_APPROVAL_DURATION());
    }
  }

  /*//////////////////////////////////////////////////////////////
                            SIGNATURE HANDLERS
  //////////////////////////////////////////////////////////////*/

  /// @notice Approve a transaction hash as one of the Safe owners
  /// @dev Tests hash approval and signature threshold mechanics
  /// @param _signerSeed Random seed for selecting a signer
  /// @param _hashSeed Random seed for selecting a transaction hash
  function handler_approveHash(uint256 _signerSeed, uint256 _hashSeed) public usingSigner(_signerSeed) {
    if (ghost_hashes.length == 0) return; // avoid mod 0
    bytes32 _hash = ghost_hashes[_hashSeed % ghost_hashes.length];

    vm.prank(currentSigner);
    try safe.approveHash(_hash) {
    // Hash approval is part of Safe, we don't track it here
    }
    catch {
      assertEq(_hash, bytes32(0));
    }
  }

  /*//////////////////////////////////////////////////////////////
                            EXECUTION HANDLERS
  //////////////////////////////////////////////////////////////*/

  /// @notice Execute a queued transaction
  /// @dev Tests execution timing, authorization, and emergency mode
  /// @param _seed Random seed for selecting a transaction
  function handler_executeTransaction(uint256 _seed) public {
    if (ghost_hashes.length == 0) {
      return;
    }
    bytes32 _hash = ghost_hashes[_seed % ghost_hashes.length];
    address _actionsBuilder = ghost_hashToActionsBuilder[_hash];

    // If in emergency mode, only emergency caller can execute
    address caller = canonGuard.emergencyMode() ? canonGuard.emergencyCaller() : address(this);

    // Reset the action target contract
    vm.etch(address(actionTarget), address(new ActionTarget()).code);

    vm.prank(caller);
    try canonGuard.executeTransaction(_actionsBuilder) {
      _assertPostCondition(_actionsBuilder);
    } catch Error(string memory _reason) {
      assertEq(_reason, 'GS020');
    } catch (bytes memory _reason) {
      assertTrue(_isTimingError(_reason));
      _assertTimingError(_reason, _actionsBuilder);
    }
  }

  /*//////////////////////////////////////////////////////////////
                            CONFIGURATION HANDLERS
  //////////////////////////////////////////////////////////////*/

  /// @notice Change the short transaction execution delay
  /// @dev Tests redeployment and configuration changes
  /// @param _shortTxExecutionDelay New short delay (must be <= long delay)
  function handler_changeShortTxDelay(uint256 _shortTxExecutionDelay) public {
    _shortTxExecutionDelay = bound(_shortTxExecutionDelay, 1, canonGuard.LONG_TX_EXECUTION_DELAY());

    // get current params
    uint256 _longTxExecutionDelay = canonGuard.LONG_TX_EXECUTION_DELAY();
    uint256 _txExpiryDelay = canonGuard.TX_EXPIRY_DELAY();
    uint256 _maxApprovalDuration = canonGuard.MAX_APPROVAL_DURATION();
    address _emergencyTrigger = canonGuard.emergencyTrigger();
    address _emergencyCaller = canonGuard.emergencyCaller();

    // redeploy with same params except new delay
    canonGuard = CanonGuard(
      canonGuardFactory.createCanonGuard(
        address(safe),
        _shortTxExecutionDelay,
        _longTxExecutionDelay,
        _txExpiryDelay,
        _maxApprovalDuration,
        _emergencyTrigger,
        _emergencyCaller
      )
    );

    // set the new entrypoint as guard
    vm.prank(address(safe));
    safe.setGuard(address(canonGuard));
  }

  /// @notice Change the long transaction execution delay
  /// @dev Tests redeployment with new long delay
  /// @param _longTxExecutionDelay New long delay (must be >= short delay)
  function handler_changeLongTxDelay(uint256 _longTxExecutionDelay) public {
    _longTxExecutionDelay = bound(_longTxExecutionDelay, canonGuard.SHORT_TX_EXECUTION_DELAY(), 3650 days);

    // get current params
    uint256 _shortTxExecutionDelay = canonGuard.SHORT_TX_EXECUTION_DELAY();
    uint256 _txExpiryDelay = canonGuard.TX_EXPIRY_DELAY();
    uint256 _maxApprovalDuration = canonGuard.MAX_APPROVAL_DURATION();
    address _emergencyTrigger = canonGuard.emergencyTrigger();
    address _emergencyCaller = canonGuard.emergencyCaller();

    // redeploy with same params except new delay
    canonGuard = CanonGuard(
      canonGuardFactory.createCanonGuard(
        address(safe),
        _shortTxExecutionDelay,
        _longTxExecutionDelay,
        _txExpiryDelay,
        _maxApprovalDuration,
        _emergencyTrigger,
        _emergencyCaller
      )
    );

    // set the new entrypoint as guard
    vm.prank(address(safe));
    safe.setGuard(address(canonGuard));
  }

  /// @notice Change the transaction expiry delay
  /// @dev Tests redeployment with new expiry delay
  /// @param _txExpiryDelay New expiry delay
  function handler_changeTxExpiryDelay(uint256 _txExpiryDelay) public {
    _txExpiryDelay = bound(_txExpiryDelay, canonGuard.MIN_EXPIRY_TIME(), 3650 days);

    // get current params
    uint256 _shortTxExecutionDelay = canonGuard.SHORT_TX_EXECUTION_DELAY();
    uint256 _longTxExecutionDelay = canonGuard.LONG_TX_EXECUTION_DELAY();
    uint256 _maxApprovalDuration = canonGuard.MAX_APPROVAL_DURATION();
    address _emergencyTrigger = canonGuard.emergencyTrigger();
    address _emergencyCaller = canonGuard.emergencyCaller();

    // redeploy with same params except new delay
    canonGuard = CanonGuard(
      canonGuardFactory.createCanonGuard(
        address(safe),
        _shortTxExecutionDelay,
        _longTxExecutionDelay,
        _txExpiryDelay,
        _maxApprovalDuration,
        _emergencyTrigger,
        _emergencyCaller
      )
    );

    // set the new entrypoint as guard
    vm.prank(address(safe));
    safe.setGuard(address(canonGuard));
  }

  /// @notice Change the maximum approval duration
  /// @dev Tests redeployment with new max approval duration
  /// @param _maxApprovalDuration New max approval duration
  function handler_changeMaxApprovalDuration(uint256 _maxApprovalDuration) public {
    _maxApprovalDuration = bound(_maxApprovalDuration, canonGuard.MIN_EXPIRY_TIME(), 365 days);

    // get current params
    uint256 _shortTxExecutionDelay = canonGuard.SHORT_TX_EXECUTION_DELAY();
    uint256 _longTxExecutionDelay = canonGuard.LONG_TX_EXECUTION_DELAY();
    uint256 _txExpiryDelay = canonGuard.TX_EXPIRY_DELAY();
    address _emergencyTrigger = canonGuard.emergencyTrigger();
    address _emergencyCaller = canonGuard.emergencyCaller();

    // redeploy with same params except new delay
    canonGuard = CanonGuard(
      canonGuardFactory.createCanonGuard(
        address(safe),
        _shortTxExecutionDelay,
        _longTxExecutionDelay,
        _txExpiryDelay,
        _maxApprovalDuration,
        _emergencyTrigger,
        _emergencyCaller
      )
    );

    // set the new entrypoint as guard
    vm.prank(address(safe));
    safe.setGuard(address(canonGuard));
  }

  /*//////////////////////////////////////////////////////////////
                            POST-EXECUTION VALIDATION
  //////////////////////////////////////////////////////////////*/

  function _assertPostCondition(address _actionsBuilder) internal {
    if (ghost_actionsBuilderType[_actionsBuilder] == ActionsBuilderType.ALLOWANCE_CLAIMOR) {
      assertTrue(actionTarget.isTransferFromCalled());
      assertEq(actionTarget.transferFromSender(), TOKEN_SENDER);
      assertEq(actionTarget.transferFromRecipient(), TOKEN_RECIPIENT);
      // min between allowance and sender balance (see ActionTarget contract - balance is 123, allowance is 789)
      assertEq(actionTarget.transferFromAmount(), 123);
    } else if (ghost_actionsBuilderType[_actionsBuilder] == ActionsBuilderType.SIMPLE_ACTIONS) {
      assertTrue(actionTarget.isDepositCalled());
      assertTrue(actionTarget.isTransferCalled());
      assertEq(actionTarget.transferRecipient(), TOKEN_RECIPIENT);
      assertEq(actionTarget.transferAmount(), AMOUNT);
    } else if (ghost_actionsBuilderType[_actionsBuilder] == ActionsBuilderType.SIMPLE_TRANSFERS) {
      assertTrue(actionTarget.isTransferCalled());
      assertEq(actionTarget.transferRecipient(), TOKEN_RECIPIENT);
      assertEq(actionTarget.transferAmount(), AMOUNT);
    } else if (ghost_actionsBuilderType[_actionsBuilder] == ActionsBuilderType.OPX_ACTION) {
      assertTrue(actionTarget.isDowngraded());
      assertEq(actionTarget.downgradeAmount(), 123);
    } else if (ghost_actionsBuilderType[_actionsBuilder] == ActionsBuilderType.EVERCLEAR_TOKEN_CONVERSION) {
      assertTrue(actionTarget.isApproved());
      assertEq(actionTarget.approveSpender(), address(actionTarget)); // lockbox
      assertEq(actionTarget.approveAmount(), 123);
      assertTrue(actionTarget.isERC20Deposited());
      assertEq(actionTarget.depositAmount(), 123);
    } else if (ghost_actionsBuilderType[_actionsBuilder] == ActionsBuilderType.EVERCLEAR_TOKEN_STAKE) {
      assertTrue(actionTarget.isClaimed());
      assertEq(actionTarget.claimRecipient(), TOKEN_RECIPIENT);
      assertTrue(actionTarget.isReleased());
      assertTrue(actionTarget.isApproved());
      assertEq(actionTarget.approveSpender(), TOKEN_RECIPIENT);
      assertEq(actionTarget.approveAmount(), 123);
      assertTrue(actionTarget.isIncreaseLockPositionCalled());
      assertEq(actionTarget.lockPositionAmount(), 123);
      assertEq(actionTarget.lockTime(), 123);
      assertEq(actionTarget.gasLimit(), 123);
      assertTrue(actionTarget.isUpdateStateCalled());
      assertEq(actionTarget.updateStateData(), abi.encode(123, 123));
    } else if (ghost_actionsBuilderType[_actionsBuilder] == ActionsBuilderType.CAPPED_TOKEN_TRANSFERS_HUB) {
      // Hub-based builders can have varying recipients and amounts, so just verify transfer was called
      assertTrue(actionTarget.isTransferCalled());
      // The recipient should be one of the signers (as hubs use signers[0])
      assertTrue(actionTarget.transferAmount() > 0);
    }
  }

  /*//////////////////////////////////////////////////////////////
                            EMERGENCY HANDLERS
  //////////////////////////////////////////////////////////////*/

  /// @notice Set emergency mode
  /// @dev Tests emergency mode activation and its effects
  function handler_setEmergencyMode() public {
    // Only the emergency trigger can set emergency mode
    address trigger = canonGuard.emergencyTrigger();
    vm.prank(trigger);
    canonGuard.setEmergencyMode();
    assertTrue(canonGuard.emergencyMode());
    _recordEmergencyMode();
  }

  /*//////////////////////////////////////////////////////////////
                            CANCELLATION HANDLERS
  //////////////////////////////////////////////////////////////*/

  /// @notice Cancel an enqueued transaction
  /// @dev Tests cancellation permissions and conditions
  /// @param _seed Random seed for selecting a transaction
  function handler_cancelEnqueuedTransaction(uint256 _seed) public {
    if (ghost_hashes.length == 0) return;
    bytes32 _hash = ghost_hashes[_seed % ghost_hashes.length];
    address _actionsBuilder = ghost_hashToActionsBuilder[_hash];

    // Try to cancel as the proposer or in emergency mode
    try canonGuard.cancelEnqueuedTransaction(_actionsBuilder) {
      // Verify transaction was removed from queue
      address[] memory queuedBuilders = canonGuard.getQueuedActionBuilders();
      for (uint256 i = 0; i < queuedBuilders.length; i++) {
        assertTrue(queuedBuilders[i] != _actionsBuilder);
      }
    } catch (bytes memory _reason) {
      // Expected failures: not proposer, has signatures, not queued
      bool isExpectedError = bytes4(_reason) == bytes4(keccak256('CallerMustBeTransactionProposer()'))
        || bytes4(_reason) == bytes4(keccak256('TransactionWithSignaturesCannotBeCancelled()'))
        || bytes4(_reason) == bytes4(keccak256('NoTransactionQueued()'))
        || bytes4(_reason) == bytes4(keccak256('Unauthorized(address,address)'));
      assertTrue(isExpectedError);
    }
  }

  /*//////////////////////////////////////////////////////////////
                            BATCH EXECUTION HANDLERS
  //////////////////////////////////////////////////////////////*/

  /// @notice Execute multiple transactions in a batch
  /// @dev Tests batch execution mechanics and nonce handling
  /// @param _seed Random seed for selecting transactions
  /// @param _count Number of transactions to execute (bounded to 1-5)
  function handler_executeTransactions(uint256 _seed, uint256 _count) public {
    if (ghost_hashes.length == 0) return;
    uint256 maxCount = ghost_hashes.length > 5 ? 5 : ghost_hashes.length;
    if (maxCount == 0) return;
    _count = bound(_count, 1, maxCount);

    address[] memory _actionsBuilders = new address[](_count);
    for (uint256 i = 0; i < _count; i++) {
      // Use modulo on seed to prevent overflow
      bytes32 _hash = ghost_hashes[((_seed % ghost_hashes.length) + i) % ghost_hashes.length];
      _actionsBuilders[i] = ghost_hashToActionsBuilder[_hash];
    }

    // If in emergency mode, only emergency caller can execute
    address caller = canonGuard.emergencyMode() ? canonGuard.emergencyCaller() : address(this);

    // Reset action target for each builder
    for (uint256 i = 0; i < _count; i++) {
      vm.etch(address(actionTarget), address(new ActionTarget()).code);
    }

    vm.prank(caller);
    try canonGuard.executeTransactions(_actionsBuilders) {
      // Verify all transactions were removed from queue
      for (uint256 i = 0; i < _count; i++) {
        (,, uint256 _expiresAt,,) = canonGuard.transactionsInfo(_actionsBuilders[i]);
        assertEq(_expiresAt, 0);
      }
    } catch Error(string memory _reason) {
      assertEq(_reason, 'GS020');
    } catch (bytes memory _reason) {
      assertTrue(_isTimingError(_reason) || bytes4(_reason) == bytes4(keccak256('Unauthorized(address,address)')));
    }
  }

  /// @notice Execute a no-action transaction (nonce increment only)
  /// @dev Tests nonce management without executing any actions
  function handler_executeNoActionTransaction() public {
    uint256 _nonceBefore = safe.nonce();

    // If in emergency mode, only emergency caller can execute
    address caller = canonGuard.emergencyMode() ? canonGuard.emergencyCaller() : address(this);

    vm.prank(caller);
    try canonGuard.executeNoActionTransaction() {
      // Verify nonce was incremented
      assertEq(safe.nonce(), _nonceBefore + 1);
    } catch Error(string memory _reason) {
      assertEq(_reason, 'GS020');
    } catch (bytes memory _reason) {
      assertTrue(bytes4(_reason) == bytes4(keccak256('Unauthorized(address,address)')));
    }
  }
}
