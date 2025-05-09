// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ISimpleTransfers} from 'interfaces/actions/ISimpleTransfers.sol';

contract SimpleTransfers is ISimpleTransfers {
  Action[] public actions;

  constructor(Transfer[] memory _transfers) {
    uint256 _transfersLength = _transfers.length;
    Transfer memory transfer;
    Action memory standardAction;
    string memory signature;
    bytes4 selector;
    bytes memory completeCallData;

    for (uint256 i; i < _transfersLength; ++i) {
      transfer = _transfers[i];

      signature = 'transfer(address,uint256)';
      selector = bytes4(keccak256(bytes(signature)));
      completeCallData = abi.encodePacked(selector, transfer.to, transfer.amount);

      standardAction = Action({target: transfer.token, data: completeCallData, value: 0});

      actions.push(standardAction);
      emit SimpleActionAdded(transfer.token, signature, completeCallData, 0);
    }
  }

  function getActions() external view returns (Action[] memory _actions) {
    _actions = actions;
  }
}
