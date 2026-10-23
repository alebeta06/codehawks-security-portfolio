// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import {Test} from "forge-std/Test.sol";
import {PuppyRaffle} from "../src/PuppyRaffle.sol";

contract PuppyRaffleDoSTest is Test {
    PuppyRaffle public puppyRaffle;

    uint256 entranceFee = 1e18;
    address feeAddress = address(99);
    uint256 duration = 1 days;

    function setUp() public {
        puppyRaffle = new PuppyRaffle(entranceFee, feeAddress, duration);
    }

    function test_dos_entering_gets_more_expensive() public {
        uint256 groupSize = 100;

        // First batch enters an empty array: few duplicate comparisons.
        address[] memory first = new address[](groupSize);
        for (uint256 i = 0; i < groupSize; i++) {
            first[i] = address(uint160(i + 1));
        }
        uint256 gasBefore1 = gasleft();
        puppyRaffle.enterRaffle{value: entranceFee * groupSize}(first);
        uint256 gasFirst = gasBefore1 - gasleft();

        // Second batch enters with 100 players already in: many more comparisons.
        address[] memory second = new address[](groupSize);
        for (uint256 i = 0; i < groupSize; i++) {
            second[i] = address(uint160(i + 1 + groupSize)); // 101..200
        }
        uint256 gasBefore2 = gasleft();
        puppyRaffle.enterRaffle{value: entranceFee * groupSize}(second);
        uint256 gasSecond = gasBefore2 - gasleft();

        assertGt(gasSecond, gasFirst); // entering gets more expensive: DoS
    }
}
