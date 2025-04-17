// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

import {ISimpleActions} from 'interfaces/actions/ISimpleActions.sol';

interface ISimpleActionsFactory {
  /**
   * NOTE: in Etherscan interface, the transaction should be parsed as follows:
   * Describing a WETH.deposit{value:1}() & WETH.transfer(0x0000000000000000000000000000000000C0FFEE, 1)
   *  [
   *    [
   *      "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
   *      "deposit()",
   *      "0x",
   *      "1"
   *    ],
   *    [
   *      "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
   *      "transfer(address,uint256)",
   *      "0x0000000000000000000000000000000000000000000000000000000000c0ffee0000000000000000000000000000000000000000000000000000000000000001",
   *      "0"
   *    ]
   *  ]
   *
   * Where 0x0000000000000000000000000000000000000000000000000000000000c0ffee0000000000000000000000000000000000000000000000000000000000000001
   * is the result of abi.encode(address(0xC0FFEE), uint256(1))
   */
  function createSimpleActions(ISimpleActions.SimpleAction[] memory _actions) external returns (address);
}
