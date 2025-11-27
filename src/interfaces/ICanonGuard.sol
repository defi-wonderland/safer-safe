// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IEmergencyModeHook} from 'interfaces/IEmergencyModeHook.sol';
import {IOnlyCanonGuard} from 'interfaces/IOnlyCanonGuard.sol';

/**
 * @title ICanonGuard
 * @notice Interface for the CanonGuard contract
 */
interface ICanonGuard is IOnlyCanonGuard, IEmergencyModeHook {
  // ~~~ STRUCTS ~~~

  /**
   * @notice Information about a transaction
   * @param proposer The address of the proposer of the transaction
   * @param actionsData The encoded actions data
   * @param executableAt The timestamp from which the transaction can be executed
   * @param expiresAt The timestamp from which the transaction expires
   * @param isPreApproved Whether the transaction is pre-approved
   */
  struct TransactionInfo {
    address proposer;
    bytes actionsData;
    uint256 executableAt;
    uint256 expiresAt;
    bool isPreApproved;
  }

  // ~~~ EVENTS ~~~

  /**
   * @notice Emitted when an actions builder is approved
   * @param _actionsBuilderOrHub The address of the actions builder or hub contract
   * @param _approvalDuration The duration (in seconds) of the approval to the actions builder or hub contract (0 means disapproval)
   * @param _approvalExpiresAt The timestamp from which the actions builder or hub contract is no longer approved to be queued
   */
  event ActionsBuilderOrHubApproved(
    address indexed _actionsBuilderOrHub, uint256 indexed _approvalDuration, uint256 indexed _approvalExpiresAt
  );

  /**
   * @notice Emitted when a transaction is queued
   * @param _proposer The address of the proposer of the transaction
   * @param _actionsBuilder The actions builder contract address
   * @param _actionHub The actionHub contract address (0 if no actionHub was used)
   * @param _txIsPreApproved Whether the transaction is pre-approved
   */
  event TransactionQueued(
    address indexed _proposer, address indexed _actionsBuilder, address indexed _actionHub, bool _txIsPreApproved
  );

  /**
   * @notice Emitted when a transaction is executed
   * @param _actionsBuilder The actions builder contract address
   * @param _safeTxHash The hash of the Safe transaction
   * @param _signers The array of sorted signer addresses.
   * @param _txIsPreApproved Whether the transaction is pre-approved (short delay) or not (long delay)
   */
  event TransactionExecuted(
    address indexed _actionsBuilder, bytes32 indexed _safeTxHash, address[] _signers, bool _txIsPreApproved
  );

  /**
   * @notice Emitted when an empty transaction is executed
   * @param _safeTxHash The hash of the Safe transaction
   * @param _signers The array of signer addresses
   */
  event NoActionTransactionExecuted(bytes32 indexed _safeTxHash, address[] _signers);

  /**
   * @notice Emitted when a enqueued transaction is cancelled
   * @param _actionsBuilder The actions builder contract address
   * @param _proposer The address of the proposer of the transaction
   */
  event EnqueuedTransactionCancelled(address indexed _actionsBuilder, address indexed _proposer);

  /**
   * @notice Emitted when dust is collected
   * @param _token The token sent to the SAFE contract
   * @param _balance The balance of the token sent to the SAFE contract
   */
  event DustCollected(address indexed _token, uint256 _balance);

  /**
   * @notice Thrown when no transaction is queued for the actions builder
   */
  error NoTransactionQueued();

  /**
   * @notice Thrown when a transaction is not yet executable
   */
  error TransactionNotYetExecutable();

  /**
   * @notice Thrown when a transaction has expired
   */
  error TransactionExpired();

  /**
   * @notice Thrown when attempting to queue a transaction that has already been queued
   * @param _actionsBuilder The address of the actions builder contract
   */
  error TransactionAlreadyQueued(address _actionsBuilder);

  /**
   * @notice Thrown when queuing an action builder that has an invalid ActionHub parent
   */
  error InvalidActionBuilderHubParent();

  /**
   * @notice Thrown when an invalid approval duration is provided
   */
  error InvalidApprovalDuration();

  /**
   * @notice Thrown when the delay configuration is invalid
   */
  error InvalidDelayConfiguration();

  /**
   * @notice Thrown when the short transaction execution delay is greater than the long transaction execution delay
   */
  error ShortDelayCannotBeGreaterThanLongDelay();

  /**
   * @notice Thrown when the transaction expiry delay is greater than the maximum value (uint128.max)
   */
  error TxExpiryDelayCannotBeGreaterThanMax();

  /**
   * @notice Thrown when the long transaction execution delay is greater than the maximum value
   */
  error LongDelayCannotBeGreaterThanMax();

  /**
   * @notice Thrown when the caller is not the proposer of the transaction being cancelled
   */
  error CallerMustBeTransactionProposer();

  /**
   * @notice Thrown when the MultiSendCallOnly contract is the zero address
   */
  error ZeroMultiSendCallOnly();

  /**
   * @notice Thrown when the transaction expiry delay is less than the minimum expiry time
   */
  error TxExpiryDelayCannotBeLessThanMin();

  /**
   * @notice Thrown when the maximum approval duration is less than the minimum expiry time
   */
  error MaxApprovalDurationCannotBeLessThanMin();

  // ~~~ ADMIN METHODS ~~~

  /**
   * @notice Approves an actions builder to be queued
   * @dev Can only be called by the Safe contract
   * @param _actionsBuilder The address of the actions builder contract to approve
   * @param _approvalDuration The duration (in seconds) of the approval to the actions builder contract (0 means disapproval)
   */
  function approveActionsBuilderOrHub(address _actionsBuilder, uint256 _approvalDuration) external;

  // ~~~ TRANSACTION METHODS ~~~

  /**
   * @notice Queues a transaction from an actions builder for execution after a short delay if approved, or after a long delay if not approved
   * @dev Can only be called by the Safe owners
   * @param _actionsBuilder The actions builder contract address to queue. Reverts if it is not an ActionsBuilder.
   */
  function queueTransaction(address _actionsBuilder) external;

  /**
   * @notice Executes a queued transaction using the approved hash signers
   * @dev Can be called by anyone
   * @dev The transaction must have passed its execution delay period, but not its expiry delay period
   * @param _actionsBuilder The actions builder contract address of the transaction to execute
   */
  function executeTransaction(address _actionsBuilder) external;

  /**
   * @notice Executes multiple queued transactions using the approved hash signers
   * @dev Can be called by anyone
   * @dev The transactions must have passed their execution delay period, but not their expiry delay period
   * @dev Each transaction must have been approved using consecutive SAFE nonces.
   * @param _actionsBuilders The array of actions builder contract addresses of the transactions to execute
   */
  function executeTransactions(address[] memory _actionsBuilders) external;

  /**
   * @notice Executes an empty transaction, in order to use the safe nonce.
   * @notice This will nullify the signatures for that specific safe nonce.
   * @dev Can be called by anyone if not in emergency mode
   */
  function executeNoActionTransaction() external;

  /**
   * @notice Cancels an enqueued transaction
   * @dev Can only be called by the proposer of the transaction
   * @param _actionsBuilder The actions builder contract address
   */
  function cancelEnqueuedTransaction(address _actionsBuilder) external;

  /**
   * @notice Collects dust (ETH or ERC20 tokens) from the contract and sends it to the SAFE contract.
   * @dev Can be called by anyone. If balance is zero, nothing happens.
   * @param _token The token to collect dust from. Zero address for ETH.
   */
  function collectDust(address _token) external;

  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Gets the address that represents ETH for dust collection
   * @return _ethAddress The ETH address
   */
  function ETH_ADDRESS() external view returns (address _ethAddress);

  /**
   * @notice Gets the parent address
   * @return _parent The parent address. Returns address(0) if it was not deployed by a factory
   */
  function PARENT() external view returns (address _parent);

  /**
   * @notice Gets the MultiSendCallOnly contract
   * @return _multiSendCallOnly The MultiSendCallOnly contract address
   */
  function MULTI_SEND_CALL_ONLY() external view returns (address _multiSendCallOnly);

  /**
   * @notice Gets the short execution delay applied to pre-approved transactions
   * @return _shortTxExecutionDelay The short transaction execution delay (in seconds)
   */
  function SHORT_TX_EXECUTION_DELAY() external view returns (uint256 _shortTxExecutionDelay);

  /**
   * @notice Gets the long execution delay applied to not approved transactions
   * @return _longTxExecutionDelay The long transaction execution delay (in seconds)
   */
  function LONG_TX_EXECUTION_DELAY() external view returns (uint256 _longTxExecutionDelay);

  /**
   * @notice Gets the default expiry delay for transactions
   * @return _txExpiryDelay The default transaction expiry delay (in seconds)
   */
  function TX_EXPIRY_DELAY() external view returns (uint256 _txExpiryDelay);

  /**
   * @notice Gets the maximum approval duration
   * @return _maxApprovalDuration The maximum approval duration for an actions builder or hub (in seconds)
   */
  function MAX_APPROVAL_DURATION() external view returns (uint256 _maxApprovalDuration);

  /**
   * @notice Gets the minimum expiry time
   * @return _minExpiryTime The minimum expiry time (in seconds)
   */
  function MIN_EXPIRY_TIME() external view returns (uint256 _minExpiryTime);

  /**
   * @notice Gets the maximum transaction execution delay
   * @return _maxTxExecutionDelay The maximum transaction execution delay (in seconds)
   */
  function MAX_TX_EXECUTION_DELAY() external view returns (uint256 _maxTxExecutionDelay);

  /**
   * @notice Gets the approval expiry time for an actions builder
   * @param _actionsBuilder The address of the actions builder contract
   * @return _approvalExpiresAt The timestamp from which the actions builder contract is no longer approved to be queued
   */
  function approvalExpiries(address _actionsBuilder) external view returns (uint256 _approvalExpiresAt);

  /**
   * @notice Gets the transaction info for an queued actions builder
   * @return _proposer The address of the proposer of the transaction
   * @param _actionsBuilder The actions builder contract address
   * @return _actionsData The encoded actions data
   * @return _executableAt The timestamp from which the transaction can be executed
   * @return _expiresAt The timestamp from which the transaction expires
   * @return _isPreApproved Whether the transaction is pre-approved (short delay) or not (long delay)
   */
  function transactionsInfo(address _actionsBuilder)
    external
    view
    returns (
      address _proposer,
      bytes memory _actionsData,
      uint256 _executableAt,
      uint256 _expiresAt,
      bool _isPreApproved
    );

  // ~~~ GETTER METHODS ~~~

  /**
   * @notice Gets the Safe transaction hash for an actions builder. If the actions builder is the zero address, it will return the hash of an empty transaction.
   * @param _actionsBuilder The actions builder contract address
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTransactionHash(address _actionsBuilder) external view returns (bytes32 _safeTxHash);

  /**
   * @notice Gets the Safe transaction hash for an actions builder with a specific Safe nonce. If the actions builder is the zero address, it will return the hash of an empty transaction.
   * @param _actionsBuilder The actions builder contract address
   * @param _safeNonce The Safe nonce to use for the hash calculation
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTransactionHash(
    address _actionsBuilder,
    uint256 _safeNonce
  ) external view returns (bytes32 _safeTxHash);

  /**
   * @notice Gets the list of signers who have approved a Safe transaction hash for an actions builder with a specific Safe nonce
   * @param _actionsBuilder The actions builder contract address. Or the zero address if you want to execute an empty transaction
   * @param _safeNonce The Safe nonce to use for the hash calculation
   * @return _approvedHashSigners The array of approved hash signer addresses
   */
  function getApprovedHashSigners(
    address _actionsBuilder,
    uint256 _safeNonce
  ) external view returns (address[] memory _approvedHashSigners);

  /**
   * @notice Gets the Safe nonce
   * @return _safeNonce The Safe nonce
   */
  function getSafeNonce() external view returns (uint256 _safeNonce);

  /**
   * @notice Gets the list of action builders in the queue
   * @dev The actions builders are not sorted
   * @return _queuedActionBuilders The array of action builders in the queue
   */
  function getQueuedActionBuilders() external view returns (address[] memory _queuedActionBuilders);
}
