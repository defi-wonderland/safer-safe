// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

import {SimpleTransfers} from '../SimpleTransfers.sol';

contract SimpleTransfersFactory {
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
  function createSimpleTransfers(SimpleTransfers.Transfer[] memory _transfers) external returns (address) {
    return address(new SimpleTransfers(_transfers));
  }
}
