// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IActionsBuilder} from 'interfaces/actions/IActionsBuilder.sol';

interface IAllowanceClaimor is IActionsBuilder {
  function SAFE() external view returns (address _safe);
  function TOKEN() external view returns (address _token);
  function TOKEN_OWNER() external view returns (address _tokenOwner);
  function TOKEN_RECIPIENT() external view returns (address _tokenRecipient);
}
