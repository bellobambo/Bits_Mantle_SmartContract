// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Bits} from "../src/Bits.sol";

contract BitsScript is Script {
    Bits public bits;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        bits = new Bits();

        vm.stopBroadcast();
    }
}
