// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {AllowanceClaimorFactory} from 'contracts/factories/AllowanceClaimorFactory.sol';
import {Test} from 'forge-std/Test.sol';
import {IAllowanceClaimor} from 'interfaces/actions-builders/IAllowanceClaimor.sol';

contract UnitAllowanceClaimorFactorycreateAllowanceClaimor is Test {
  AllowanceClaimorFactory public allowanceClaimorFactory;
  IAllowanceClaimor public auxAllowanceClaimor;

  function setUp() external {
    allowanceClaimorFactory = new AllowanceClaimorFactory();
  }

  function test_WhenCalled(address _safe, address _token, address _tokenOwner, address _tokenRecipient) external {
    address _allowanceClaimor =
      allowanceClaimorFactory.createAllowanceClaimor(_safe, _token, _tokenOwner, _tokenRecipient);

    auxAllowanceClaimor =
      IAllowanceClaimor(deployCode('AllowanceClaimor', abi.encode(_safe, _token, _tokenOwner, _tokenRecipient)));

    // it should deploy a AllowanceClaimor contract
    assertEq(address(auxAllowanceClaimor).code, _allowanceClaimor.code);

    // it should match the parameters sent to the constructor
    assertEq(IAllowanceClaimor(_allowanceClaimor).SAFE(), _safe);
    assertEq(address(IAllowanceClaimor(_allowanceClaimor).TOKEN()), _token);
    assertEq(IAllowanceClaimor(_allowanceClaimor).TOKEN_OWNER(), _tokenOwner);
    assertEq(IAllowanceClaimor(_allowanceClaimor).TOKEN_RECIPIENT(), _tokenRecipient);

    // it should store the contract as a factory children
    assertTrue(allowanceClaimorFactory.isChild(_allowanceClaimor));
  }
}
