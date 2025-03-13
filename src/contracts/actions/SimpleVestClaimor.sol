// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import {IActions} from '../../interfaces/IActions.sol';

interface ISimpleVestingEscrow {
  function claim() external returns (uint256);
}

contract SimpleVestClaimor is IActions {
  address[] public vestingEscrows;

  function setVestingEscrows(address[] memory _vestingEscrows) external isAuthorized {
    for (uint256 i = 0; i < _vestingEscrows.length; i++) {
      vestingEscrows.push(_vestingEscrows[i]);
    }
  }

  function getActions() external returns (Action[] memory) {
    Action[] memory actions = new Action[](vestingEscrows.length);
    for (uint256 i = 0; i < vestingEscrows.length; i++) {
      actions[i] =
        Action({target: vestingEscrows[i], data: abi.encodeWithSelector(ISimpleVestingEscrow.claim.selector), value: 0});
    }
    return actions;
  }

  modifier isAuthorized() {
    // TODO: check if sender is msig signer
    // TODO: abstract to be reused across all actions
    _;
  }
}
