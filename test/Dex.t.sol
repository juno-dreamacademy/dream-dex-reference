// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Dex.sol";

contract DexTest is Test {
    Dex public dex;

    function setUp() public {
        dex = new Dex();
    }
}
