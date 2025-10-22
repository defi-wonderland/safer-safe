// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ISafeManageable} from 'interfaces/ISafeManageable.sol';

/**
 * @title ICappedTokenTransfersHub
 * @notice Interface for the CappedTokenTransfersHub contract
 */
interface ICappedTokenTransfersHub is ISafeManageable {
  // ~~~ EVENTS ~~~

  /**
   * @notice Emitted when the state is updated for a token with a certain amount
   * @param _token The token that was updated
   * @param _amountSpent The amount of tokens that were spent
   * @param _currentEpoch The current epoch after the update
   * @param _capLeft The cap left for the token in the current epoch
   */
  event StateUpdated(address indexed _token, uint256 _amountSpent, uint256 _currentEpoch, uint256 _capLeft);

  // ~~~ ERRORS ~~~

  /**
   * @notice Thrown when the cap is exceeded
   */
  error CapExceeded();

  /**
   * @notice Thrown when creating a hub actions builder for a token that is not registered in the hub
   */
  error TokenNotRegisteredInHub();

  /**
   * @notice Thrown when the epoch length is zero
   */
  error EpochLengthCannotBeZero();

  /**
   * @notice Thrown when the tokens registered contain a duplicated token
   * @param _token The token that is duplicated
   */
  error TokenAlreadyRegisteredInHub(address _token);

  // ~~~ FUNCTIONS ~~~

  /**
   * @notice Checks if the spending cap is exceeded and resets the spending if we're in a new epoch.
   * @param _token The token to update the state for
   * @param _amount The amount of tokens to update the state for. Reverts if the spending cap is exceeded with this amount.
   */
  function updateState(address _token, uint256 _amount) external;

  /**
   * @notice Creates a new actions builder.
   * @notice Reverts if the token is not registered in the hub.
   * @param _token The token to cap
   * @param _amount The amount of tokens to transfer
   * @return _actionsBuilder The address of the new actions builder
   */
  function createNewActionsBuilder(address _token, uint256 _amount) external returns (address _actionsBuilder);

  /**
   * @notice Gets the recipient
   * @return _recipient The recipient
   */
  function RECIPIENT() external view returns (address _recipient);

  /**
   * @notice Gets the epoch length.
   * @return _epochLength The epoch length
   */
  function EPOCH_LENGTH() external view returns (uint256 _epochLength);

  /**
   * @notice Gets the starting timestamp
   * @return _startingTimestamp The starting timestamp
   */
  function STARTING_TIMESTAMP() external view returns (uint256 _startingTimestamp);

  /**
   * @notice Gets the current epoch
   * @return _currentEpoch The current epoch
   */
  function currentEpoch() external view returns (uint256 _currentEpoch);

  /**
   * @notice Gets the total amount of tokens spent
   * @param _token The token to get the total amount of tokens spent for
   * @return _totalSpent The total amount of tokens spent
   */
  function totalSpent(address _token) external view returns (uint256 _totalSpent);

  /**
   * @notice Gets the cap for a token
   * @param _token The token to get the cap for
   * @return _cap The cap for the token
   */
  function cap(address _token) external view returns (uint256 _cap);

  /**
   * @notice Gets the tokens
   * @return _tokens The tokens registered in the hub
   */
  function tokens() external view returns (address[] memory _tokens);

  /**
   * @notice Gets the cap left for a token in the current epoch
   * @param _token The token to get the cap left for
   * @return _capLeft The cap left for the token in the current epoch
   */
  function capLeft(address _token) external view returns (uint256 _capLeft);
}
