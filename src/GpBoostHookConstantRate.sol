// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IPrizeHooks, PrizeHooks } from "../lib/pt-v5-vault/src/interfaces/IPrizeHooks.sol";
import { Claimable } from "../lib/pt-v5-vault/src/abstract/Claimable.sol";
import { PrizePool } from "../lib/pt-v5-prize-pool/src/PrizePool.sol";
import { VaultBoosterFactory } from "../lib/pt-v5-vault-boost/src/VaultBoosterFactory.sol";
import { VaultBooster, IERC20, SafeERC20 } from "../lib/pt-v5-vault-boost/src/VaultBooster.sol";

/// @title PoolTogether V5 - Constant Rate Grand Prize Booster
/// @notice Uses both hook calls to redirect all prizes won (except the GP) to a vault booster that is set to re-contribute
/// tokens on behalf of this hook, creating a continuous loop of contributions until the booster's reserves are depleted.
/// The end result of this hook is to contribute a constant stream of capital to the grand prize with predictable impact to 
/// other prize pool participants.
/// @dev If the GP is won by this "vault", the hook will revert any claims, thus forcing the GP value to remain in the
/// prize pool.
/// @author G9 Software Inc.
contract GpBoostHookConstantRate is IPrizeHooks, Claimable {
    using SafeERC20 for IERC20;

    /// @notice Thrown if the GP is won by this contract
    error LeaveTheGpInThePrizePool();

    /// @notice The vault booster that prizes will be redirected to and then looped back into the prize pool from
    VaultBooster public immutable VAULT_BOOSTER;

    /// @notice Constructs a new GP Boost Hook
    /// @param prizePool_ The prize pool that the prizes originate from
    /// @param claimer_ The permitted claimer for prizes
    /// @param vaultBoosterFactory_ The factory to use for creating the vault booster
    /// @param vaultBoosterOwner_ The owner of the vault booster that is created to stream funds to the GP
    constructor(PrizePool prizePool_, address claimer_, VaultBoosterFactory vaultBoosterFactory_, address vaultBoosterOwner_) Claimable(prizePool_, claimer_) {
        // Initialize a TWAB for this contract so it can win prizes
        prizePool.twabController().mint(address(this), 1e18);

        // Ensure this contract uses it's own hooks for wins
        _hooks[address(this)] = PrizeHooks({
            useBeforeClaimPrize: false,
            useAfterClaimPrize: true,
            implementation: IPrizeHooks(address(this))
        });

        // Create the vault booster that will stream prizes won back into the prize pool
        VAULT_BOOSTER = vaultBoosterFactory_.createVaultBooster(prizePool_, address(this), vaultBoosterOwner_);
    }

    /// @inheritdoc IPrizeHooks
    /// @dev Included to complete the interface; does nothing
    function beforeClaimPrize(address, uint8, uint32, uint96, address) external view returns (address, bytes memory) { }

    /// @inheritdoc IPrizeHooks
    /// @dev Reverts if the prize is the GP.
    /// @dev Redirects any prizes won to the vault booster to be streamed back into the prize pool over time.
    function afterClaimPrize(address, uint8 tier, uint32, uint256 prizeAmount, address, bytes memory) external {
        if (tier == 0) {
            revert LeaveTheGpInThePrizePool();
        } else if (prizeAmount > 0) {
            IERC20 prizeToken = prizePool.prizeToken();
            prizeToken.forceApprove(address(VAULT_BOOSTER), prizeAmount);
            VAULT_BOOSTER.deposit(prizeToken, prizeAmount);
        }
    }
}