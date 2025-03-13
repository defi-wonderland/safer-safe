// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import {IActions} from '../../interfaces/IActions.sol';

interface IConnextVestingEscrow {
  function claim(address) external;
  function release() external;
}

contract ConnextVestClaimor is IActions {
  address public constant CONNEXT_VESTING_ESCROW = 0xbf6c61d8f4D16Ed61D38b895ffb76D3107852b99;
  address public constant CONNEXT_VESTING_WALLET = 0x7DAE0a882bd4511fa6918e6A35B21aD31a89E3Ab;

  function getActions() external returns (Action[] memory) {
    Action[] memory actions = new Action[](2);

    actions[0] = Action({
      target: CONNEXT_VESTING_WALLET,
      data: abi.encodeWithSelector(IConnextVestingEscrow.claim.selector, CONNEXT_VESTING_ESCROW),
      value: 0
    });

    actions[1] = Action({
      target: CONNEXT_VESTING_WALLET,
      data: abi.encodeWithSelector(IConnextVestingEscrow.release.selector),
      value: 0
    });

    return actions;
  }

  modifier isAuthorized() {
    // TODO: check if sender is msig signer
    // TODO: abstract to be reused across all actions
    _;
  }
}
