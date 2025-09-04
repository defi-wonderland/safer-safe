// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ISafeManageable} from 'interfaces/ISafeManageable.sol';
import {IActionHub} from 'interfaces/action-hubs/IActionHub.sol';

/**
 * @title ICappedTokenTransfersHub
 * @notice Interface for the CappedTokenTransfersHub contract
 */
interface ICappedTokenTransfersHub is IActionHub, ISafeManageable {
  // ~~~ ERRORS ~~~

  /**
   * @notice Thrown when the cap is exceeded
   */
  error CapExceeded();

  // ~~~ FUNCTIONS ~~~

  /**
   * @notice Updates the state. Checks if the cap is exceeded and resets the spending if we're in a new epoch.
   * @param _data The data to update the state with
   * @dev The data is a tuple of (amount, token)
   */
  function updateState(bytes memory _data) external;

  /**
   * @notice Creates a new action builder
   * @param _token The token to cap
   * @param _amount The amount of tokens to transfer
   * @return _actionBuilder The address of the new action builder
   */
  function createNewActionBuilder(address _token, uint256 _amount) external returns (address _actionBuilder);

  /**
   * @notice Gets the recipient
   * @return _recipient The recipient
   */
  function RECIPIENT() external view returns (address _recipient);

  /**
   * @notice Gets the epoch length
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
   * @notice Gets the tokens
   * @return _tokens The tokens
   */
  function tokens() external view returns (address[] memory _tokens);

  /**
   * @notice Gets the caps
   * @return _caps The caps
   */
  function caps() external view returns (uint256[] memory _caps);

  /**
   * @notice Gets the cap left for a token in the current epoch
   * @param _token The token to get the cap left for
   * @return _capLeft The cap left
   */
  function capLeft(address _token) external view returns (uint256 _capLeft);
}
