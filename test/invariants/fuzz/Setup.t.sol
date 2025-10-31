// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';

import {Safe} from '@safe-smart-account/Safe.sol';
import {SafeProxyFactory} from '@safe-smart-account/proxies/SafeProxyFactory.sol';

import {HandlersTarget} from './HandlersTarget.t.sol';

import {MultiSendCallOnly} from './utils/MultiSendCallOnly.sol';
import {CanonGuard} from 'contracts/CanonGuard.sol';

import {AllowanceClaimorFactory} from 'contracts/factories/AllowanceClaimorFactory.sol';

import {CanonGuardFactory} from 'contracts/factories/CanonGuardFactory.sol';
import {CappedTokenTransfersHubFactory} from 'contracts/factories/CappedTokenTransfersHubFactory.sol';
import {SimpleActionsFactory} from 'contracts/factories/SimpleActionsFactory.sol';
import {SimpleTransfersFactory} from 'contracts/factories/SimpleTransfersFactory.sol';

import {Constants} from 'script/Constants.sol';
import {Utils} from 'test/unit/utils/Utils.sol';

contract Setup is Test, Constants, Utils {
  SafeProxyFactory private _safeProxyFactory;
  Safe private _safeSingleton;
  MultiSendCallOnly private _multiSendCallOnly;
  CanonGuardFactory private _canonGuardFactory;
  CanonGuard private _canonGuard;
  Safe private _safe;

  AllowanceClaimorFactory public allowanceClaimorFactory;
  CappedTokenTransfersHubFactory public cappedTokenTransfersHubFactory;
  SimpleActionsFactory public simpleActionsFactory;
  SimpleTransfersFactory public simpleTransfersFactory;

  // handlers
  HandlersTarget public handlersTarget;

  function setUp() public {
    vm.warp(10);

    address[] memory _signers = new address[](5);
    _signers[0] = makeAddr('signer1');
    _signers[1] = makeAddr('signer2');
    _signers[2] = makeAddr('signer3');
    _signers[3] = makeAddr('signer4');
    _signers[4] = makeAddr('signer5');

    vm.etch(address(CREATE_X), _getCreateXDeployedBytecode());

    _safeProxyFactory = new SafeProxyFactory();
    _safeSingleton = new Safe();

    _multiSendCallOnly = new MultiSendCallOnly();

    _safe = Safe(payable(_safeProxyFactory.createProxyWithNonce(address(_safeSingleton), bytes(''), 1)));

    _canonGuardFactory = new CanonGuardFactory();

    _safe.setup({
      _owners: _signers,
      _threshold: 3,
      to: address(0),
      data: bytes(''),
      fallbackHandler: address(0),
      paymentToken: address(0),
      payment: 0,
      paymentReceiver: payable(address(0))
    });

    vm.prank(address(_safe));
    _canonGuard = CanonGuard(
      _canonGuardFactory.createCanonGuard(
        address(_safe),
        address(_multiSendCallOnly),
        SHORT_TX_EXECUTION_DELAY,
        LONG_TX_EXECUTION_DELAY,
        TX_EXPIRY_DELAY,
        MAX_APPROVAL_DURATION,
        address(1),
        address(1)
      )
    );

    vm.prank(address(_safe));
    _safe.setGuard(address(_canonGuard));

    handlersTarget = new HandlersTarget(_canonGuard, _canonGuardFactory, _safe, _signers);
    targetContract(address(handlersTarget));
  }
}
