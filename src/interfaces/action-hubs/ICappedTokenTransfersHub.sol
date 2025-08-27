// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ISafeManageable} from 'interfaces/ISafeManageable.sol';
import {IActionHub} from 'interfaces/action-hubs/IActionHub.sol';

/**
 * @title ICappedTokenTransfersHub
 * @notice Interface for the CappedTokenTransfersHub contract
 */
interface ICappedTokenTransfersHub is IActionHub, ISafeManageable {
  /**
   * @notice Thrown when the cap is exceeded
   */
  error CapExceeded();

  /**
   * @notice Thrown when the epoch length is zero
   */
  error EpochLengthCannotBeZero();

  /**
   * @notice Updates the state. Checks if the cap is exceeded and resets the spending if we're in a new epoch.
   * @param _token The token to update the state for
   * @param _amount The amount of tokens to update the state for
   */
  function updateState(address _token, uint256 _amount) external;

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
   * @notice Gets the cap
   * @param _token The token to get the cap for
   * @return _cap The cap
   */
  function cap(address _token) external view returns (uint256 _cap);

  /**
   * @notice Gets the total amount of tokens spent
   * @param _token The token to get the total amount of tokens spent for
   * @return _totalSpent The total amount of tokens spent
   */
  function totalSpent(address _token) external view returns (uint256 _totalSpent);

  /**
   * @notice Gets the list of tokens capped
   * @return _tokens List of token addresses
   */
  function tokens() external view returns (address[] memory _tokens);
}
