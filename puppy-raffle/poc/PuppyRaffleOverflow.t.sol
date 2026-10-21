// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import {Test} from "forge-std/Test.sol";
import {PuppyRaffle} from "../src/PuppyRaffle.sol";

contract PuppyRaffleOverflowTest is Test {
    PuppyRaffle public puppyRaffle;

    uint256 entranceFee = 1e18;
    address feeAddress = address(99);
    uint256 duration = 1 days;

    function setUp() public {
        puppyRaffle = new PuppyRaffle(entranceFee, feeAddress, duration);
    }

    function test_fee_overflow_locks_withdrawals() public {
        uint256 playerCount = 93;
        address[] memory players = new address[](playerCount);
        for (uint256 i = 0; i < playerCount; i++) {
            players[i] = address(uint160(i + 1));
        }
        puppyRaffle.enterRaffle{value: entranceFee * playerCount}(players);
        vm.warp(block.timestamp + duration + 1);
        puppyRaffle.selectWinner();
        uint256 feesRecorded = puppyRaffle.totalFees();
        uint256 feesExpected = (entranceFee * playerCount * 20) / 100;
        assertLt(feesRecorded, feesExpected);
        vm.expectRevert("PuppyRaffle: There are currently players active!");
        puppyRaffle.withdrawFees();
    }
}
