// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {CappedTokenTransfersHub} from 'contracts/action-hubs/CappedTokenTransfersHub.sol';
import {Factory} from 'contracts/factories/Factory.sol';
import {ICappedTokenTransfersHubFactory} from 'interfaces/factories/ICappedTokenTransfersHubFactory.sol';

/**
 * @title CappedTokenTransfersHubFactory
 * @notice Contract that deploys CappedTokenTransfersHub contracts
 */
contract CappedTokenTransfersHubFactory is ICappedTokenTransfersHubFactory, Factory {
  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc ICappedTokenTransfersHubFactory
  function createCappedTokenTransfersHub(
    address _safe,
    address _recipient,
    address[] memory _tokens,
    uint256[] memory _caps,
    uint256 _epochLength
  ) external returns (address _cappedTokenTransfersHub) {
    _cappedTokenTransfersHub = address(
      new CappedTokenTransfersHub(address(this), _safe, _recipient, _tokens, _caps, _epochLength)
    );

    _children[_cappedTokenTransfersHub] = true;

    emit CappedTokenTransfersHubCreated(_cappedTokenTransfersHub, _safe, _recipient);
  }
}
