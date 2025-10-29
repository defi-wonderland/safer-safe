// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IFactory} from 'interfaces/factories/IFactory.sol';

/**
 * @title IPreApproveActionFactory
 * @notice Interface for the PreApproveActionFactory contract
 */
interface IPreApproveActionFactory is IFactory {
  // ~~~ EVENTS ~~~

  /**
   * @notice Emitted when a new PreApproveAction contract is created
   * @param _preApproveAction The address of the created PreApproveAction contract
   * @param _actionsBuilder The actions builder contract address
   * @param _approvalDuration The approval duration
   */
  event PreApproveActionCreated(
    address indexed _preApproveAction, address indexed _actionsBuilder, uint256 _approvalDuration
  );

  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates an PreApproveAction contract
   * @param _actionsBuilder The actions builder contract address
   * @param _approvalDuration The approval duration
   * @return _preApproveAction The PreApproveAction contract address
   */
  function createPreApproveAction(
    address _actionsBuilder,
    uint256 _approvalDuration
  ) external returns (address _preApproveAction);
}
