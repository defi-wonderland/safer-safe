# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Safer Safe is a multisig solution that enhances security through fully on-chain Actions contracts and dynamic timelocks. The system is built on top of Safe smart contracts and provides a safer way to execute transactions with time delays and approval mechanisms.

## Core Architecture

### Key Components

1. **SafeEntrypoint**: Main contract that allows execution of transactions on a Safe with time delays and approval mechanisms
2. **ActionHub**: Abstract contract for managing action builders - contracts that define specific transaction patterns
3. **Actions Builders**: Specific implementations for different transaction types (SimpleActions, CappedTokenTransfers, etc.)
4. **SafeManageable**: Base contract providing Safe integration functionality
5. **EmergencyModeHook**: Security mechanism to pause operations in emergency situations
6. **OnlyEntrypointGuard**: Guard that ensures transactions go through the proper entrypoint

### Directory Structure

- `src/contracts/`: Core contract implementations
- `src/interfaces/`: Interface definitions
- `test/unit/`: Unit tests isolated from externalities
- `test/integration/`: Integration tests that run on blockchain forks
- `test/invariants/`: Invariant tests using Medusa fuzzing
- `script/`: Deployment scripts

## Development Commands

### Building
- `yarn build` - Fast build (development)
- `yarn build:optimized` - Optimized build via IR compilation

### Testing
- `yarn test` - Run all tests (unit + integration)
- `yarn test:unit` - Run only unit tests
- `yarn test:unit:deep` - Run unit tests with 5x more fuzzing
- `yarn test:integration` - Run only integration tests
- `yarn test:fuzz` - Run Medusa fuzzing campaign (requires Medusa installed)
- `yarn test:symbolic` - Run symbolic execution tests (requires Halmos installed)
- `yarn coverage` - Generate code coverage report

### Code Quality
- `yarn lint:check` - Check formatting and linting
- `yarn lint:fix` - Fix formatting and linting issues
- `yarn lint:sol` - Run Solhint on Solidity files
- `yarn lint:bulloak` - Check .tree files in test/unit

### Deployment
- `yarn deploy:ethereum:entrypoint` - Deploy entrypoint to Ethereum
- `yarn deploy:ethereum:safer-safe` - Deploy safer-safe to Ethereum
- `yarn deploy:optimism:entrypoint` - Deploy entrypoint to Optimism
- `yarn deploy:optimism:safer-safe` - Deploy safer-safe to Optimism

## Technical Details

### Foundry Configuration
- Solidity version: 0.8.29
- EVM version: Prague
- Optimizer runs: 10,000
- Via IR enabled for test and optimized profiles
- Invariant testing timeout: 1200 seconds
- Fuzz runs: 1000

### Dependencies
- Safe contracts: `@safe-global/safe-contracts`
- Solady utilities: `solady`
- Forge standard library: `forge-std`

### Testing Strategy
- Unit tests use `.tree` files with bulloak for test specification
- Integration tests fork mainnet/optimism networks
- Invariant testing uses Medusa fuzzer with corpus storage
- Symbolic execution available via Halmos

### Key Patterns
- CREATE3 for deterministic address deployment
- Time-delayed execution with configurable delays
- Approval-based action builder management
- Emergency mode for pausing operations
- Guard-based transaction validation

## Setup Requirements

1. Install Foundry
2. Install Rust dependencies: `cargo install lintspec`
3. Install Node dependencies: `yarn install`
4. Copy `.env.example` to `.env` and configure variables
5. For deployment: Import private keys to Foundry keystore using `cast wallet import`