// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/**
 * @title IApproveActionFactory
 * @notice Interface for the ApproveActionFactory contract
 */
interface IApproveActionFactory {
  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates an ApproveAction contract
   * @param _canonGuard The CanonGuard contract address
   * @param _actionsBuilder The actions builder contract address
   * @param _approvalDuration The approval duration
   * @return _approveAction The ApproveAction contract address
   */
  function createApproveAction(
    address _canonGuard,
    address _actionsBuilder,
    uint256 _approvalDuration
  ) external returns (address _approveAction);
}
