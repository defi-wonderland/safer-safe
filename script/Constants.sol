// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ICanonGuardFactory} from 'interfaces/factories/ICanonGuardFactory.sol';

import {ISafe} from '@safe-smart-account/interfaces/ISafe.sol';
import {MultiSendCallOnly} from '@safe-smart-account/libraries/MultiSendCallOnly.sol';
import {SafeProxyFactory} from '@safe-smart-account/proxies/SafeProxyFactory.sol';

import {IERC20} from 'forge-std/interfaces/IERC20.sol';

abstract contract Constants {
  // Safe Deployments (https://github.com/safe-global/safe-deployments/tree/main/src/assets/v1.4.1)
  ISafe public constant SAFE = ISafe(0x41675C099F32341bf84BFc5382aF534df5C7461a);
  SafeProxyFactory public constant SAFE_PROXY_FACTORY = SafeProxyFactory(0x4e1DCf7AD4e460CfD30791CCC4F9c8a4f820ec67);
  MultiSendCallOnly public constant MULTI_SEND_CALL_ONLY = MultiSendCallOnly(0x9641d764fc13c8B624c04430C7356C1C7C8102e2);

  // Canon Guard
  ICanonGuardFactory public constant CANON_GUARD_FACTORY =
    ICanonGuardFactory(0x34A1D3fff3958843C43aD80F30b94c510645C316); // TODO: Replace with the address of the CanonGuardFactory contract once deployed

  // Wonderland Canon Guard
  ISafe public constant SAFE_PROXY = ISafe(0x74fEa3FB0eD030e9228026E7F413D66186d3D107);
  uint256 public constant SHORT_TX_EXECUTION_DELAY = 1 hours;
  uint256 public constant LONG_TX_EXECUTION_DELAY = 7 days;
  uint256 public constant TX_EXPIRY_DELAY = 7 days;
  uint256 public constant MAX_APPROVAL_DURATION = 4 * 365 days;
  // TODO: Replace with the correct address
  address public constant EMERGENCY_TRIGGER = address(1);
  address public constant EMERGENCY_CALLER = address(1);
}

abstract contract EthereumConstants is Constants {
  // Ethereum tokens
  IERC20 public constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  IERC20 public constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  IERC20 public constant USDS = IERC20(0xdC035D45d973E3EC169d2276DDab16f1e407384F);
  IERC20 public constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  IERC20 public constant L3 = IERC20(0x88909D489678dD17aA6D9609F89B0419Bf78FD9a);
  IERC20 public constant GRT = IERC20(0xc944E90C64B2c07662A292be6244BDf05Cda44a7);
  IERC20 public constant GTC = IERC20(0xDe30da39c46104798bB5aA3fe8B9e0e1F348163F);
  IERC20 public constant CLEAR = IERC20(0x58b9cB810A68a7f3e1E4f8Cb45D1B9B3c79705E8);
  IERC20 public constant NEXT = IERC20(0xFE67A4450907459c3e1FFf623aA927dD4e28c67a);
  IERC20 public constant BAL = IERC20(0xba100000625a3754423978a60c9317c58a424e3D);
  IERC20 public constant EIGEN = IERC20(0xec53bF9167f50cDEB3Ae105f56099aaaB9061F83);
  IERC20 public constant KP3R = IERC20(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);
}

abstract contract OptimismConstants is Constants {
  // Optimism tokens
  IERC20 public constant WETH = IERC20(0x4200000000000000000000000000000000000006);
  IERC20 public constant OP = IERC20(0x4200000000000000000000000000000000000042);
  IERC20 public constant KITE = IERC20(0xf467C7d5a4A9C4687fFc7986aC6aD5A4c81E1404);
  IERC20 public constant WLD = IERC20(0xdC6fF44d5d932Cbd77B52E5612Ba0529DC6226F1);
}
