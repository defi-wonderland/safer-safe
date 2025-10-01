// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ActionTarget, BaseHandlers} from './BaseHandlers.sol';

import {SimpleActionsFactory} from 'contracts/factories/SimpleActionsFactory.sol';
import {ISimpleActions} from 'interfaces/actions-builders/ISimpleActions.sol';

abstract contract HandlersSimpleActions is BaseHandlers {
  function handler_queueSimpleAction(uint256 _approvalDuration) public {
    _approvalDuration = bound(_approvalDuration, 1, 1000);

    ISimpleActions.SimpleAction memory _depositAction =
      ISimpleActions.SimpleAction({target: address(actionTarget), signature: 'deposit()', data: bytes(''), value: 0});
    ISimpleActions.SimpleAction memory _transferAction = ISimpleActions.SimpleAction({
      target: address(actionTarget),
      signature: 'transfer(address,uint256)',
      data: abi.encode(TOKEN_RECIPIENT, AMOUNT),
      value: 0
    });

    ISimpleActions.SimpleAction[] memory _simpleActions = new ISimpleActions.SimpleAction[](2);
    _simpleActions[0] = _depositAction;
    _simpleActions[1] = _transferAction;

    address actionsBuilder = simpleActionsFactory.createSimpleActions(_simpleActions);

    vm.prank(address(safe));
    try canonGuard.approveActionsBuilderOrHub(actionsBuilder, _approvalDuration) {
      vm.prank(signers[0]);
      canonGuard.queueTransaction(actionsBuilder);

      bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(actionsBuilder);

      ghost_hashToActionsBuilder[_safeTxHash] = actionsBuilder;
      ghost_hashes.push(_safeTxHash);
      ghost_timestampOfActionQueued[_safeTxHash] = block.timestamp;
      ghost_actionsBuilderType[actionsBuilder] = ActionsBuilderType.SIMPLE_ACTIONS;
    } catch {
      assertGt(_approvalDuration, canonGuard.MAX_APPROVAL_DURATION());
    }
  }
}
