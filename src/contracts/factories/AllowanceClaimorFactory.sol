// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {AllowanceClaimor} from 'contracts/actions-builders/AllowanceClaimor.sol';
import {Factory} from 'contracts/factories/Factory.sol';
import {IAllowanceClaimorFactory} from 'interfaces/factories/IAllowanceClaimorFactory.sol';

/**
 * @title AllowanceClaimorFactory
 * @notice Contract that deploys AllowanceClaimor contracts
 */
contract AllowanceClaimorFactory is IAllowanceClaimorFactory, Factory {
  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc IAllowanceClaimorFactory
  function createAllowanceClaimor(
    address _safe,
    address _token,
    address _tokenOwner,
    address _tokenRecipient
  ) external returns (address _allowanceClaimor) {
    _allowanceClaimor = address(new AllowanceClaimor(address(this), _safe, _token, _tokenOwner, _tokenRecipient));

    _contractsCreated[_allowanceClaimor] = true;
  }
}
