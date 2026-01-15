// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IArbitraryActions} from 'interfaces/actions-builders/IArbitraryActions.sol';
import {IFactory} from 'interfaces/factories/IFactory.sol';

/**
 * @title IArbitraryActionsFactory
 * @notice Interface for the ArbitraryActionsFactory contract
 */
interface IArbitraryActionsFactory is IFactory {
  // ~~~ EVENTS ~~~

  /**
   * @notice Emitted when a new ArbitraryActions contract is created
   * @param _arbitraryActions The address of the created ArbitraryActions contract
   */
  event ArbitraryActionsCreated(address indexed _arbitraryActions);

  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates an ArbitraryActions contract
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
   * @param _actions The array of arbitrary actions
   * @return _arbitraryActions The ArbitraryActions contract address
   */
  function createArbitraryActions(IArbitraryActions
        .ArbitraryAction[] memory _actions) external returns (address _arbitraryActions);

  /**
   * @notice Creates an ArbitraryActions contract with a single arbitrary action
   * @dev In Etherscan interface, the transaction should be parsed as follows:
   * Describing a WETH.transfer(0x0000000000000000000000000000000000C0FFEE, 1):
   *  "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
   *  "transfer(address,uint256)",
   *  "0x0000000000000000000000000000000000000000000000000000000000c0ffee0000000000000000000000000000000000000000000000000000000000000001",
   *  "0"
   * Where 0x0000000000000000000000000000000000000000000000000000000000c0ffee0000000000000000000000000000000000000000000000000000000000000001
   * is the result of abi.encode(address(0xC0FFEE), uint256(1))
   * @param _arbitraryAction The arbitrary action
   * @return _arbitraryActions The ArbitraryActions contract address
   */
  function createArbitraryAction(
    IArbitraryActions.ArbitraryAction memory _arbitraryAction
  ) external returns (address _arbitraryActions);
}
