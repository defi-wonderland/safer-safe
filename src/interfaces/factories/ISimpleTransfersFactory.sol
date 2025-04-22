// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ISimpleTransfers} from 'interfaces/actions/ISimpleTransfers.sol';

interface ISimpleTransfersFactory {
  /**
   * NOTE: in Etherscan interface, the transaction should be parsed as follows:
   * Describing a WETH.transfer(address(0xc0ffee), 1)
   *  [
   *    [
   *      "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
   *      "0x0000000000000000000000000000000000C0FFEE",
   *      "1"
   *    ]
   *  ]
   */
  function createSimpleTransfers(ISimpleTransfers.Transfer[] memory _transfers) external returns (address);
}
