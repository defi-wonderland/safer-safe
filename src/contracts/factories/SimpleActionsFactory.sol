// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {SimpleActions} from 'contracts/actions-builders/SimpleActions.sol';
import {Factory} from 'contracts/factories/Factory.sol';
import {ISimpleActions} from 'interfaces/actions-builders/ISimpleActions.sol';
import {ISimpleActionsFactory} from 'interfaces/factories/ISimpleActionsFactory.sol';

/**
 * @title SimpleActionsFactory
 * @notice Contract that deploys SimpleActions contracts
 */
contract SimpleActionsFactory is ISimpleActionsFactory, Factory {
  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc ISimpleActionsFactory
  function createSimpleActions(ISimpleActions.SimpleAction[] calldata _smplActions)
    external
    returns (address _simpleActions)
  {
    _simpleActions = address(new SimpleActions(address(this), _smplActions));

    _contractsCreated[_simpleActions] = true;
  }
}
