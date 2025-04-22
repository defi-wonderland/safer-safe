// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

import {ITransactionBuilder} from 'interfaces/actions/ITransactionBuilder.sol';

interface IAllowanceClaimor is ITransactionBuilder {
  function SAFE() external view returns (address _safe);
  function TOKEN() external view returns (address _token);
  function TOKEN_OWNER() external view returns (address _tokenOwner);
  function TOKEN_RECIPIENT() external view returns (address _tokenRecipient);
}
