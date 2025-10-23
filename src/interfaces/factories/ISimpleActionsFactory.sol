// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ISimpleActions} from 'interfaces/actions-builders/ISimpleActions.sol';

/**
 * @title ISimpleActionsFactory
 * @notice Interface for the SimpleActionsFactory contract
 */
interface ISimpleActionsFactory {
  // ~~~ EVENTS ~~~

  /**
   * @notice Emitted when a new SimpleActions contract is created
   * @param _simpleActions The address of the created SimpleActions contract
   * @param _creator The address that created the contract
   */
  event SimpleActionsCreated(address indexed _simpleActions, address indexed _creator);

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
   * @param _smplActions The array of simple actions
   * @return _simpleActions The SimpleActions contract address
   */
  function createSimpleActions(ISimpleActions
        .SimpleAction[] memory _smplActions) external returns (address _simpleActions);

  /**
   * @notice Creates a SimpleActions contract with a single simple action
   * @dev In Etherscan interface, the transaction should be parsed as follows:
   * Describing a WETH.transfer(0x0000000000000000000000000000000000C0FFEE, 1):
   *  "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
   *  "transfer(address,uint256)",
   *  "0x0000000000000000000000000000000000000000000000000000000000c0ffee0000000000000000000000000000000000000000000000000000000000000001",
   *  "0"
   * Where 0x0000000000000000000000000000000000000000000000000000000000c0ffee0000000000000000000000000000000000000000000000000000000000000001
   * is the result of abi.encode(address(0xC0FFEE), uint256(1))
   * @param _simpleAction The simple action
   * @return _simpleActions The SimpleActions contract address
   */
  function createSimpleAction(
    ISimpleActions.SimpleAction memory _simpleAction
  ) external returns (address _simpleActions);
}
