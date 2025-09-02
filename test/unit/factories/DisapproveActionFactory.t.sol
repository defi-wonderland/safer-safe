// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {DisapproveActionFactory} from 'contracts/factories/DisapproveActionFactory.sol';
import {Test} from 'forge-std/Test.sol';
import {IDisapproveAction} from 'interfaces/actions-builders/IDisapproveAction.sol';

contract UnitDisapproveActionFactorycreateDisapproveAction is Test {
  DisapproveActionFactory public disapproveActionFactory;
  IDisapproveAction public auxDisapproveAction;

  function setUp() external {
    disapproveActionFactory = new DisapproveActionFactory();
  }

  function test_WhenCalled(address _safeEntrypoint, address _actionsBuilder) external {
    address _disapproveAction = disapproveActionFactory.createDisapproveAction(_safeEntrypoint, _actionsBuilder);

    auxDisapproveAction =
      IDisapproveAction(deployCode('DisapproveAction', abi.encode(_safeEntrypoint, _actionsBuilder)));

    // it should deploy a DisapproveAction
    assertEq(address(auxDisapproveAction).code, _disapproveAction.code);

    // it should match the parameters sent to the constructor
    assertEq(IDisapproveAction(_disapproveAction).SAFE_ENTRYPOINT(), _safeEntrypoint);
    assertEq(IDisapproveAction(_disapproveAction).ACTIONS_BUILDER(), _actionsBuilder);
  }
}
