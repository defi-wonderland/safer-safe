// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IFactory} from 'interfaces/factories/IFactory.sol';

/**
 * @title ICanonGuardFactory
 * @notice Interface for the CanonGuardFactory contract
 */
interface ICanonGuardFactory is IFactory {
  // ~~~ ERRORS ~~~
  /**
   * @notice Thrown when the transaction expiry delay is less than the minimum expiry time
   */
  error TxExpiryDelayCannotBeLessThanMin();

  /**
   * @notice Thrown when the maximum approval duration is less than the minimum expiry time
   */
  error MaxApprovalDurationCannotBeLessThanMin();

  /**
   * @notice Thrown when the MultiSendCallOnly contract address is zero
   */
  error MultiSendCallOnlyCannotBeZero();

  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates a CanonGuard contract
   * @param _safe The Gnosis Safe contract address
   * @param _shortTxExecutionDelay The short transaction execution delay (in seconds)
   * @param _longTxExecutionDelay The long transaction execution delay (in seconds)
   * @param _txExpiryDelay The transaction expiry delay (in seconds after executable)
   * @param _maxApprovalDuration The maximum approval duration for an actions builder or hub (in seconds)
   * @param _emergencyTrigger The emergency trigger address
   * @param _emergencyCaller The emergency caller address
   * @return _canonGuard The CanonGuard contract address
   */
  function createCanonGuard(
    address _safe,
    uint256 _shortTxExecutionDelay,
    uint256 _longTxExecutionDelay,
    uint256 _txExpiryDelay,
    uint256 _maxApprovalDuration,
    address _emergencyTrigger,
    address _emergencyCaller
  ) external returns (address _canonGuard);

  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Gets the MultiSendCallOnly contract
   * @return _multiSendCallOnly The MultiSendCallOnly contract address
   */
  function MULTI_SEND_CALL_ONLY() external view returns (address _multiSendCallOnly);
}
