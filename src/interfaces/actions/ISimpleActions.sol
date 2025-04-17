// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

import {IActions} from 'interfaces/IActions.sol';

interface ISimpleActions is IActions {
  struct SimpleAction {
    address target; // e.g. WETH
    string signature; // e.g. "transfer(address,uint256)"
    bytes data; // e.g. abi.encode(address,uint256)
    uint256 value; // (msg.value)
  }

  function actions(uint256 _index) external view returns (address _target, bytes memory _data, uint256 _value);

  // ~~~ EVENTS ~~~

  event SimpleActionAdded(address indexed target, string signature, bytes data, uint256 value);
}
