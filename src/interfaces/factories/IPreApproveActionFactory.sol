// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IPreApproveActionFactory
 * @notice Interface for the PreApproveActionFactory contract
 */
interface IPreApproveActionFactory {
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
