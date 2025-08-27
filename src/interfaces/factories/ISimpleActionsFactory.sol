// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ISimpleActions} from 'interfaces/actions-builders/ISimpleActions.sol';

/**
 * @title ISimpleActionsFactory
 * @notice Interface for the SimpleActionsFactory contract
 */
interface ISimpleActionsFactory {
  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates a SimpleActions contract
   * @dev In Etherscan interface, the transaction should be parsed as follows:
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
   * Where 0x0000000000000000000000000000000000000000000000000000000000c0ffee0000000000000000000000000000000000000000000000000000000000000001
   * is the result of abi.encode(address(0xC0FFEE), uint256(1))
   * @param _simpleActions The array of simple actions
   * @return _actionBuilder The SimpleActions action builder address
   */
  function createSimpleActions(ISimpleActions.SimpleAction[] memory _simpleActions)
    external
    returns (address _actionBuilder);

  function createSimpleActions(ISimpleActions.SimpleAction memory _simpleAction)
    external
    returns (address _actionBuilder);
}
