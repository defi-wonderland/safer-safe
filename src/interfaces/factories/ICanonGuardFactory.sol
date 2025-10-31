// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ICreateX} from 'interfaces/external/ICreateX.sol';
import {IFactory} from 'interfaces/factories/IFactory.sol';

/**
 * @title ICanonGuardFactory
 * @notice Interface for the CanonGuardFactory contract
 */
interface ICanonGuardFactory is IFactory {
  // ~~~ EVENTS ~~~

  /**
   * @notice Emitted when a new CanonGuard contract is created
   * @param _canonGuard The address of the created CanonGuard contract
   * @param _safe The Gnosis Safe contract address
   * @param _emergencyTrigger The emergency trigger address
   * @param _emergencyCaller The emergency caller address
   */
  event CanonGuardCreated(
    address indexed _canonGuard, address indexed _safe, address indexed _emergencyTrigger, address _emergencyCaller
  );

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

  /**
   * @notice Thrown when the deployer is not the Safe contract
   */
  error DeployerMustBeTheSafe();

  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates a CanonGuard contract
   * @param _safe The Gnosis Safe contract address
   * @param _multiSendCallOnly The MultiSendCallOnly contract address
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
    address _multiSendCallOnly,
    uint256 _shortTxExecutionDelay,
    uint256 _longTxExecutionDelay,
    uint256 _txExpiryDelay,
    uint256 _maxApprovalDuration,
    address _emergencyTrigger,
    address _emergencyCaller
  ) external returns (address _canonGuard);

  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Gets the CreateX contract
   * @return _createX The CreateX contract address
   */
  function CREATE_X() external view returns (ICreateX _createX);
}
