// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';
import {ArbitraryActions} from 'src/contracts/actions-builders/ArbitraryActions.sol';
import {IArbitraryActions} from 'src/interfaces/actions-builders/IArbitraryActions.sol';

contract UnitArbitraryActionsconstructor is Test {
  ArbitraryActions public arbitraryActions;
  IArbitraryActions.ArbitraryAction[] public actions;

  string public constant TRANSFER_SIGNATURE = 'transfer(address,uint256)';
  string public constant APPROVE_SIGNATURE = 'approve(address,uint256)';

  modifier whenSignatureIsProvided() {
    _;
  }

  modifier setupActions(IArbitraryActions.ArbitraryAction[10] memory _actions) {
    for (uint256 _i; _i < _actions.length; _i++) {
      // if selector is provided, prepend the selector to the data
      if (bytes(_actions[_i].signature).length > 0) {
        bytes4 _expectedSelector = bytes4(keccak256(bytes(_actions[_i].signature)));
        _actions[_i].data = abi.encodePacked(_expectedSelector, _actions[_i].data);
      }

      actions.push(_actions[_i]);
    }
    _;
  }

  function test_WhenSelectorDoesNotMatchTheCallData(bytes4 _wrongSelector) external whenSignatureIsProvided {
    // Setup with signature but mismatched data (wrong selector)
    bytes4 _expectedSelector = bytes4(keccak256(bytes(TRANSFER_SIGNATURE)));
    vm.assume(_wrongSelector != _expectedSelector);

    actions.push(
      IArbitraryActions.ArbitraryAction({
        target: address(1),
        signature: TRANSFER_SIGNATURE,
        data: abi.encodePacked(_wrongSelector, abi.encode(address(0), 100)),
        value: 0
      })
    );

    // it should revert with SelectorMismatch
    vm.expectRevert(
      abi.encodeWithSelector(IArbitraryActions.SelectorMismatch.selector, _expectedSelector, _wrongSelector)
    );
    arbitraryActions = new ArbitraryActions(actions);
  }

  function test_ShouldAddTheActionsToTheActionsArrayWithCorrectValues(IArbitraryActions
        .ArbitraryAction[10] memory _actions) external setupActions(_actions) {
    arbitraryActions = new ArbitraryActions(actions);

    for (uint256 _i; _i < _actions.length; _i++) {
      IArbitraryActions.ArbitraryAction memory _arbitraryAction = _actions[_i];

      // it should add the actions to the actions array with correct values
      assertEq(arbitraryActions.getActions()[_i].target, _arbitraryAction.target);
      assertEq(arbitraryActions.getActions()[_i].data, _arbitraryAction.data);
      assertEq(arbitraryActions.getActions()[_i].value, _arbitraryAction.value);
    }
  }

  function test_ShouldEmitTheEvents(IArbitraryActions
        .ArbitraryAction[10] memory _actions) external setupActions(_actions) {
    // it should emit the events
    for (uint256 _i; _i < _actions.length; _i++) {
      vm.expectEmit();
      emit IArbitraryActions.ArbitraryActionAdded(
        _actions[_i].target, _actions[_i].data, _actions[_i].value, _actions[_i].signature
      );
    }

    arbitraryActions = new ArbitraryActions(actions);
  }

  function test_ShouldSaveTheEntireArrayOfActions(IArbitraryActions
        .ArbitraryAction[10] memory _actions) external setupActions(_actions) {
    arbitraryActions = new ArbitraryActions(actions);

    for (uint256 _i; _i < actions.length; _i++) {
      IArbitraryActions.ArbitraryAction memory _arbitraryAction = actions[_i];

      // it should save the entire array of actions
      assertEq(arbitraryActions.arbitraryActions()[_i].target, _arbitraryAction.target);
      assertEq(arbitraryActions.arbitraryActions()[_i].signature, _arbitraryAction.signature);
      assertEq(arbitraryActions.arbitraryActions()[_i].data, _arbitraryAction.data);
      assertEq(arbitraryActions.arbitraryActions()[_i].value, _arbitraryAction.value);
    }
  }
}
