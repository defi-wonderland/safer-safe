// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {SimpleTransfers} from 'contracts/actions-builders/SimpleTransfers.sol';
import {Factory} from 'contracts/factories/Factory.sol';
import {ISimpleTransfers} from 'interfaces/actions-builders/ISimpleTransfers.sol';
import {ISimpleTransfersFactory} from 'interfaces/factories/ISimpleTransfersFactory.sol';

/**
 * @title SimpleTransfersFactory
 * @notice Contract that deploys SimpleTransfers contracts
 */
contract SimpleTransfersFactory is ISimpleTransfersFactory, Factory {
  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc ISimpleTransfersFactory
  function createSimpleTransfers(ISimpleTransfers.TransferAction[] calldata _transferActions)
    external
    returns (address _simpleTransfers)
  {
    _simpleTransfers = address(new SimpleTransfers(address(this), _transferActions));

    _contractsCreated[_simpleTransfers] = true;
  }
}
