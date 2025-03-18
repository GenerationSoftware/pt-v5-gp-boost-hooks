// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";

import { GpBoostHookConstantRate, PrizePool } from "../src/GpBoostHookConstantRate.sol";
import { PrizePool } from "../lib/pt-v5-prize-pool/src/PrizePool.sol";
import { VaultBoosterFactory } from "../lib/pt-v5-vault-boost/src/VaultBoosterFactory.sol";
import { IERC20, UD2x18 } from "../lib/pt-v5-vault-boost/src/VaultBooster.sol";

contract GpBoostHookConstantRateTest is Test {

    event Deposited(address indexed token, address indexed from, uint256 amount);

    uint256 public fork;
    uint256 public forkBlock = 133325613;
    uint256 public forkTimestamp = 1742250003;
    uint256 public randomNumber = 282830497779024192640724388550852704286534307968011569641355386343626319848;

    GpBoostHookConstantRate public gpBooster;
    PrizePool public prizePool = PrizePool(address(0xF35fE10ffd0a9672d0095c435fd8767A7fe29B55));
    VaultBoosterFactory public vaultBoosterFactory = VaultBoosterFactory(address(0x7746A79332dF154e29C5b105C4d6BaE61e71DaDA));

    function setUp() public {
        fork = vm.createFork("optimism", forkBlock);
        vm.selectFork(fork);
        vm.warp(forkTimestamp);
        gpBooster = new GpBoostHookConstantRate(prizePool, address(this), vaultBoosterFactory, address(this));
        gpBooster.VAULT_BOOSTER().setBoost(
            IERC20(address(prizePool.prizeToken())),
            address(this),
            UD2x18.wrap(0),
            1,
            0
        );
        deal(address(prizePool.prizeToken()), address(this), 1e18);

        // award 100 draws to clear any other contributor's eligibility
        for (uint256 i = 0; i < 100; i++) {
            // warp to next draw
            vm.warp(prizePool.drawClosesAt(prizePool.getOpenDrawId()) + 1);

            // award draw
            vm.startPrank(prizePool.drawManager());
            prizePool.awardDraw(randomNumber);
            randomNumber = uint256(keccak256(abi.encodePacked(randomNumber)));
            vm.stopPrank();
        }
    }

    function testBeforeHookCoverage() public {
        (address redirectAddress, bytes memory returnData) = gpBooster.beforeClaimPrize(address(0), 0, 0, 0, address(0));
        assertEq(redirectAddress, address(0));
        assertEq(returnData.length, 0);
    }

    function testBoosterOwner() public {
        assertEq(gpBooster.VAULT_BOOSTER().owner(), address(this));
    }

    function testAllPrizes() public {
        bool claimedDaily = false;
        bool claimedCanary = false;
        bool triedToClaimGp = false;
        uint24 startDrawId = prizePool.getOpenDrawId();
        while (!(claimedDaily && claimedCanary && triedToClaimGp)) {
            uint24 openDrawId = prizePool.getOpenDrawId();
            require(openDrawId - startDrawId < 1000, "too many draws passed");

            // make a small contribution
            prizePool.prizeToken().transfer(address(prizePool), 1e15);
            prizePool.contributePrizeTokens(address(gpBooster), 1e15);
            assertGe(prizePool.getContributedBetween(address(gpBooster), openDrawId, openDrawId), 1e15);

            // warp to next draw
            vm.warp(prizePool.drawClosesAt(openDrawId) + 1);

            // award draw
            vm.startPrank(prizePool.drawManager());
            prizePool.awardDraw(randomNumber);
            randomNumber = uint256(keccak256(abi.encodePacked(randomNumber)));
            vm.stopPrank();

            // check for wins
            if (!claimedDaily) {
                uint256 tokensInBoosterBefore = prizePool.prizeToken().balanceOf(address(gpBooster.VAULT_BOOSTER()));
                vm.expectEmit(true, true, true, true);
                emit Deposited(address(prizePool.prizeToken()), address(gpBooster), prizePool.getTierPrizeSize(1));
                uint256 amount = _claimPrize(1, 0);
                assertEq(tokensInBoosterBefore + amount, prizePool.prizeToken().balanceOf(address(gpBooster.VAULT_BOOSTER())));
                claimedDaily = true;
            }
            if (!claimedCanary) {
                uint256 contributedBefore = prizePool.getContributedBetween(address(gpBooster), openDrawId+1, openDrawId+1);
                uint256 amount = _claimPrize(2, 0);
                uint256 contributedAfter = prizePool.getContributedBetween(address(gpBooster), openDrawId+1, openDrawId+1);
                assertEq(amount, 0);
                assertEq(contributedAfter, contributedBefore); // no contribution
                claimedCanary = true;
            }
            if (!triedToClaimGp) {
                if (prizePool.isWinner(address(gpBooster), address(gpBooster), 0, 0)) {
                    vm.expectRevert(abi.encodeWithSelector(GpBoostHookConstantRate.LeaveTheGpInThePrizePool.selector));
                    _claimPrize(0, 0);
                    triedToClaimGp = true;
                }
            }
        }
    }

    function _claimPrize(uint8 tier, uint32 prizeIndex) internal returns (uint256) {
        uint256 rewardAmount = (tier > 1 ? prizePool.getTierPrizeSize(tier) : 0); // canaries have no prize value
        uint256 prizeAmount = gpBooster.claimPrize(address(gpBooster), tier, prizeIndex, uint96(rewardAmount), address(this));
        return prizeAmount - rewardAmount;
    }

}