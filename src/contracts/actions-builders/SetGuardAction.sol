// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IGuardManager} from '@safe-smart-account/interfaces/IGuardManager.sol';
import {ActionsBuilder} from 'contracts/actions-builders/ActionsBuilder.sol';
import {ICanonGuard} from 'interfaces/ICanonGuard.sol';

/**
 * @title SetGuardAction
 * @notice This action builder sets the guard of the Safe to the address of the CanonGuard
 * It ensures that the Safe set in CanonGuard is correct, and that the canon guard set as guard is the same as the canon guard address, preventing the Safe to be bricked by wrong configuration.
 */
contract SetGuardAction is ActionsBuilder {
  /**
   * @notice Given that this contract has no factory, we need to set the parent to address(0)
   */
  constructor() ActionsBuilder(address(0)) {}

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc ActionsBuilder
  function getActions() external view override(ActionsBuilder) returns (Action[] memory _actions) {
    _actions = new Action[](1);
    _actions[0] = Action({
      target: address(ICanonGuard(msg.sender).SAFE()),
      data: abi.encodeCall(IGuardManager.setGuard, (msg.sender)),
      value: 0
    });
  }
}
