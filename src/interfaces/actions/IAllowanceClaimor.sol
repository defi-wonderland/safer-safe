// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IActions} from 'interfaces/actions/IActions.sol';

interface IAllowanceClaimor is IActions {
  function SAFE() external view returns (address _safe);
  function TOKEN() external view returns (address _token);
  function TOKEN_OWNER() external view returns (address _tokenOwner);
  function TOKEN_RECIPIENT() external view returns (address _tokenRecipient);
}
