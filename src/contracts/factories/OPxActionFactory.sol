// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {OPxAction} from 'contracts/actions-builders/OPxAction.sol';
import {Factory} from 'contracts/factories/Factory.sol';
import {IOPxActionFactory} from 'interfaces/factories/IOPxActionFactory.sol';

/**
 * @title OPxActionFactory
 * @notice Contract that deploys OPxAction contracts
 */
contract OPxActionFactory is IOPxActionFactory, Factory {
  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc IOPxActionFactory
  function createOPxAction(address _opx) external returns (address _opxAction) {
    _opxAction = address(new OPxAction(address(this), _opx));

    _children[_opxAction] = true;

    emit OPxActionCreated(_opxAction, _opx, msg.sender);
  }
}
