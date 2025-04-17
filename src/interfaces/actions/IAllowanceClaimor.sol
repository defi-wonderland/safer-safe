// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

import {IActions} from 'interfaces/IActions.sol';

interface IAllowanceClaimor is IActions {
  function SAFE() external view returns (address _safe);
  function TOKEN() external view returns (address _token);
  function TOKEN_OWNER() external view returns (address _tokenOwner);
  function TOKEN_RECIPIENT() external view returns (address _tokenRecipient);
}
