// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';
import {ArbitraryActions} from 'src/contracts/actions-builders/ArbitraryActions.sol';
import {IArbitraryActions} from 'src/interfaces/actions-builders/IArbitraryActions.sol';

contract UnitArbitraryActionsconstructor is Test {
  ArbitraryActions public arbitraryActions;
  IArbitraryActions.ArbitraryAction[] public actions;

  string constant TRANSFER_SIGNATURE = 'transfer(address,uint256)';
  string constant APPROVE_SIGNATURE = 'approve(address,uint256)';

  modifier whenSignatureIsProvided() {
    _;
  }

  function test_GivenTheSelectorMatchesTheCallData() external whenSignatureIsProvided {
    // Setup with signature and matching data
    bytes4 _transferSelector = bytes4(keccak256(bytes(TRANSFER_SIGNATURE)));
    bytes4 _approveSelector = bytes4(keccak256(bytes(APPROVE_SIGNATURE)));

    actions.push(
      IArbitraryActions.ArbitraryAction({
        target: address(1),
        signature: TRANSFER_SIGNATURE,
        data: abi.encodePacked(_transferSelector, abi.encode(address(0), 100)),
        value: 0
      })
    );

    actions.push(
      IArbitraryActions.ArbitraryAction({
        target: address(2),
        signature: APPROVE_SIGNATURE,
        data: abi.encodePacked(_approveSelector, abi.encode(address(0), 100)),
        value: 0
      })
    );

    // it should emit the events
    for (uint256 _i; _i < actions.length; _i++) {
      vm.expectEmit();
      emit IArbitraryActions.ArbitraryActionAdded(
        actions[_i].target, actions[_i].data, actions[_i].value, actions[_i].signature
      );
    }

    arbitraryActions = new ArbitraryActions(actions);

    for (uint256 _i; _i < actions.length; _i++) {
      IArbitraryActions.ArbitraryAction memory _arbitraryAction = actions[_i];

      // it should add the actions to the actions array with correct values
      assertEq(arbitraryActions.getActions()[_i].target, _arbitraryAction.target);
      assertEq(arbitraryActions.getActions()[_i].data, _arbitraryAction.data);
      assertEq(arbitraryActions.getActions()[_i].value, _arbitraryAction.value);

      // it should save the entire array of actions
      assertEq(arbitraryActions.arbitraryActions()[_i].target, _arbitraryAction.target);
      assertEq(arbitraryActions.arbitraryActions()[_i].signature, _arbitraryAction.signature);
      assertEq(arbitraryActions.arbitraryActions()[_i].data, _arbitraryAction.data);
      assertEq(arbitraryActions.arbitraryActions()[_i].value, _arbitraryAction.value);
    }
  }

  function test_GivenTheSelectorDoesNotMatchTheCallData() external whenSignatureIsProvided {
    // Setup with signature but mismatched data (wrong selector)
    bytes4 _wrongSelector = bytes4(keccak256(bytes('wrongFunction()')));
    bytes4 _expectedSelector = bytes4(keccak256(bytes(TRANSFER_SIGNATURE)));

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

  function test_WhenSignatureIsNotProvided() external {
    // Setup without signature (empty string)
    bytes4 _transferSelector = bytes4(keccak256(bytes(TRANSFER_SIGNATURE)));
    bytes4 _approveSelector = bytes4(keccak256(bytes(APPROVE_SIGNATURE)));

    actions.push(
      IArbitraryActions.ArbitraryAction({
        target: address(1),
        signature: '',
        data: abi.encodePacked(_transferSelector, abi.encode(address(0), 100)),
        value: 0
      })
    );

    actions.push(
      IArbitraryActions.ArbitraryAction({
        target: address(2),
        signature: '',
        data: abi.encodePacked(_approveSelector, abi.encode(address(0), 100)),
        value: 0
      })
    );

    // it should emit the events
    for (uint256 _i; _i < actions.length; _i++) {
      vm.expectEmit();
      emit IArbitraryActions.ArbitraryActionAdded(
        actions[_i].target, actions[_i].data, actions[_i].value, actions[_i].signature
      );
    }

    arbitraryActions = new ArbitraryActions(actions);

    for (uint256 _i; _i < actions.length; _i++) {
      IArbitraryActions.ArbitraryAction memory _arbitraryAction = actions[_i];

      // it should add the actions to the actions array with correct values
      assertEq(arbitraryActions.getActions()[_i].target, _arbitraryAction.target);
      assertEq(arbitraryActions.getActions()[_i].data, _arbitraryAction.data);
      assertEq(arbitraryActions.getActions()[_i].value, actions[_i].value);

      // it should save the entire array of actions
      assertEq(arbitraryActions.arbitraryActions()[_i].target, _arbitraryAction.target);
      assertEq(arbitraryActions.arbitraryActions()[_i].signature, _arbitraryAction.signature);
      assertEq(arbitraryActions.arbitraryActions()[_i].data, _arbitraryAction.data);
      assertEq(arbitraryActions.arbitraryActions()[_i].value, _arbitraryAction.value);
    }
  }
}
