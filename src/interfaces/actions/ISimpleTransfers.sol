// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IActionsBuilder} from 'interfaces/actions/IActionsBuilder.sol';

interface ISimpleTransfers is IActionsBuilder {
  struct Transfer {
    address token;
    address to;
    uint256 amount;
  }

  function actions(uint256 _index) external view returns (address _target, bytes memory _data, uint256 _value);

  // ~~~ EVENTS ~~~

  event SimpleActionAdded(address indexed target, string signature, bytes data, uint256 value);
}
