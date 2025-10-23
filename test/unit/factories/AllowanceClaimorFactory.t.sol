// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AllowanceClaimorFactory} from 'contracts/factories/AllowanceClaimorFactory.sol';
import {Test} from 'forge-std/Test.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {IAllowanceClaimor} from 'interfaces/actions-builders/IAllowanceClaimor.sol';
import {IAllowanceClaimorFactory} from 'interfaces/factories/IAllowanceClaimorFactory.sol';
import {Utils} from 'test/unit/utils/Utils.sol';

contract UnitAllowanceClaimorFactorycreateAllowanceClaimor is Test, Utils {
  AllowanceClaimorFactory public allowanceClaimorFactory;
  IAllowanceClaimor public auxAllowanceClaimor;

  function setUp() external {
    allowanceClaimorFactory = new AllowanceClaimorFactory();
  }

  function test_WhenCalled(address _token, address _tokenOwner, address _tokenRecipient) external {
    // it should emit AllowanceClaimorCreated event with correct parameters
    vm.expectEmit();
    emit IAllowanceClaimorFactory.AllowanceClaimorCreated(
      _getNextContractDeployedAddress(address(allowanceClaimorFactory)),
      _token,
      _tokenOwner,
      _tokenRecipient,
      address(this)
    );

    address _allowanceClaimor = allowanceClaimorFactory.createAllowanceClaimor(_token, _tokenOwner, _tokenRecipient);

    auxAllowanceClaimor = IAllowanceClaimor(
      deployCode('AllowanceClaimor', abi.encode(address(allowanceClaimorFactory), _token, _tokenOwner, _tokenRecipient))
    );

    // it should deploy a AllowanceClaimor contract
    assertEq(address(auxAllowanceClaimor).code, _allowanceClaimor.code);

    // it should match the parameters sent to the constructor
    assertEq(address(IAllowanceClaimor(_allowanceClaimor).TOKEN()), _token);
    assertEq(IAllowanceClaimor(_allowanceClaimor).TOKEN_OWNER(), _tokenOwner);
    assertEq(IAllowanceClaimor(_allowanceClaimor).TOKEN_RECIPIENT(), _tokenRecipient);

    // it should set the parent address in the child contract
    assertEq(IActionsBuilder(_allowanceClaimor).PARENT(), address(allowanceClaimorFactory));

    // it should store the contract as a factory children
    assertTrue(allowanceClaimorFactory.isChild(_allowanceClaimor));
  }
}
