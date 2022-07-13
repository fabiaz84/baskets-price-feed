pragma solidity ^0.8.1;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import "forge-std/Test.sol";
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";

contract SomeNameTest is DSTestPlus {

    function setUp() public {
    }

    function testCheckBalance() public {
        emit log_named_uint("bSTBL Balance: ", IERC20(0xAe120F0df055428E45b264E7794A18c54a2a3fAF).balanceOf(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));
    }
}

