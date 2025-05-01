// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {CappedTokenTransfers} from 'contracts/actions/CappedTokenTransfers.sol';

import {ICappedTokenTransfersFactory} from 'interfaces/factories/ICappedTokenTransfersFactory.sol';

contract CappedTokenTransfersFactory is ICappedTokenTransfersFactory {
  function createCappedTokenTransfers(
    address _safe,
    address _token,
    uint256 _cap,
    uint256 _epochLength
  ) external returns (address) {
    return address(new CappedTokenTransfers(_safe, _token, _cap, _epochLength));
  }
}
