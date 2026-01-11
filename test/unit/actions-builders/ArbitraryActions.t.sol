// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';
import {ArbitraryActions} from 'src/contracts/actions-builders/ArbitraryActions.sol';
import {IArbitraryActions} from 'src/interfaces/actions-builders/IArbitraryActions.sol';

contract UnitArbitraryActionsconstructor is Test {
  ArbitraryActions public arbitraryActions;
  IArbitraryActions.ArbitraryAction[] public actions;

  function setUp() public {
    actions.push(
      IArbitraryActions.ArbitraryAction({
        target: address(1), signature: 'transfer(address,uint256)', data: abi.encode(address(0), 100), value: 0
      })
    );

    actions.push(
      IArbitraryActions.ArbitraryAction({
        target: address(2), signature: 'approve(address,uint256)', data: abi.encode(address(0), 100), value: 0
      })
    );
  }

  function test_WhenRun() external {
    // it should emit the events
    for (uint256 _i; _i < actions.length; _i++) {
      vm.expectEmit();
      emit IArbitraryActions.ArbitraryActionAdded(
        actions[_i].target, actions[_i].signature, actions[_i].data, actions[_i].value
      );
    }

    arbitraryActions = new ArbitraryActions(actions);

    for (uint256 _i; _i < actions.length; _i++) {
      IArbitraryActions.ArbitraryAction memory _arbitraryAction = actions[_i];

      bytes4 _selector = bytes4(keccak256(bytes(_arbitraryAction.signature)));
      bytes memory _completeCallData = abi.encodePacked(_selector, _arbitraryAction.data);

      // it should add the actions to the actions array with correct values
      assertEq(arbitraryActions.getActions()[_i].target, _arbitraryAction.target);
      assertEq(arbitraryActions.getActions()[_i].data, _completeCallData);
      assertEq(arbitraryActions.getActions()[_i].value, actions[_i].value);

      // it should save the entire array of actions
      assertEq(arbitraryActions.arbitraryActions()[_i].target, _arbitraryAction.target);
      assertEq(arbitraryActions.arbitraryActions()[_i].signature, _arbitraryAction.signature);
      assertEq(arbitraryActions.arbitraryActions()[_i].data, _arbitraryAction.data);
      assertEq(arbitraryActions.arbitraryActions()[_i].value, _arbitraryAction.value);
    }
  }
}
