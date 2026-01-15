// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ArbitraryActions} from 'contracts/actions-builders/ArbitraryActions.sol';
import {Factory} from 'contracts/factories/Factory.sol';
import {IArbitraryActions} from 'interfaces/actions-builders/IArbitraryActions.sol';
import {IArbitraryActionsFactory} from 'interfaces/factories/IArbitraryActionsFactory.sol';

/**
 * @title ArbitraryActionsFactory
 * @notice Contract that deploys ArbitraryActions contracts
 */
contract ArbitraryActionsFactory is IArbitraryActionsFactory, Factory {
  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc IArbitraryActionsFactory
  function createArbitraryActions(IArbitraryActions
        .ArbitraryAction[] calldata _actions) external returns (address _arbitraryActions) {
    _arbitraryActions = address(new ArbitraryActions(_actions));

    _children[_arbitraryActions] = true;

    emit ArbitraryActionsCreated(_arbitraryActions);
  }

  /// @inheritdoc IArbitraryActionsFactory
  function createArbitraryAction(
    IArbitraryActions.ArbitraryAction calldata _arbitraryAction
  ) external returns (address _arbitraryActions) {
    IArbitraryActions.ArbitraryAction[] memory _arbitraryActionsArray = new IArbitraryActions.ArbitraryAction[](1);
    _arbitraryActionsArray[0] = _arbitraryAction;
    _arbitraryActions = address(new ArbitraryActions(_arbitraryActionsArray));

    _children[_arbitraryActions] = true;
    emit ArbitraryActionsCreated(_arbitraryActions);
  }
}
