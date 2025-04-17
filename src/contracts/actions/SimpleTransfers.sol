// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

import {ISimpleTransfers} from 'interfaces/actions/ISimpleTransfers.sol';

contract SimpleTransfers is ISimpleTransfers {
  Action[] public actions;

  constructor(Transfer[] memory _transfers) {
    for (uint256 i = 0; i < _transfers.length; i++) {
      Transfer memory transfer = _transfers[i];

      string memory signature = 'transfer(address,uint256)';
      bytes4 selector = bytes4(keccak256(bytes(signature)));
      bytes memory completeCallData = abi.encodePacked(selector, transfer.to, transfer.amount);

      Action memory standardAction = Action({target: transfer.token, data: completeCallData, value: 0});

      actions.push(standardAction);
      emit SimpleActionAdded(transfer.token, signature, completeCallData, 0);
    }
  }

  function getActions() external view returns (Action[] memory) {
    return actions;
  }
}
