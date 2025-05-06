// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {suint256} from "src/staticstate.sol";

import {console} from "forge-std/console.sol";

/// @author philogy <https://github.com/philogy>
contract StaticstateTest is Test {
    suint256 x;

    function test_fuzzing__multi_set(uint256 x1, uint256 x2) public view {
        uint256 before = gasleft();
        assertEq(x.get(), 0);
        console.log("get1: %s", before - gasleft());

        before = gasleft();
        assertEq(x.get(), 0);
        console.log("get2: %s", before - gasleft());

        before = gasleft();
        x.set(x1);
        console.log("set1: %s", before - gasleft());

        before = gasleft();
        assertEq(x.get(), x1);
        console.log("get3: %s", before - gasleft());

        before = gasleft();
        assertEq(x.get(), x1);
        console.log("get4: %s", before - gasleft());

        before = gasleft();
        x.set(x2);
        console.log("set2: %s", before - gasleft());

        before = gasleft();
        assertEq(x.get(), x2);
        console.log("get5: %s", before - gasleft());

        before = gasleft();
        assertEq(x.get(), x2);
        console.log("get6: %s", before - gasleft());
    }
}
