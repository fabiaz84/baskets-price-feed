pragma solidity ^0.8.0;

import {Constants} from "./Constants.sol";
import {BasketsPriceFeed} from "../src/BasketsPriceFeed.sol";

contract MarketsTestingSuite {

    //MARKETS CONTRACTS
    BasketsPriceFeed public basketFeed;
    //Oracle public oracle;


    Constants constants; 

    function setUp() public{
        constants = new constants();

        deployBasketsPriceFeed();
    }

    function deployBasketsPriceFeed() public {
	//Deploy BasketCompatible Oracle
        basketFeed = new BasketsPriceFeed(constants.bSTBL(), constants.lendingRegistry());
    }

    function getBasketValue() public {
    }

    function getBorrowedAmountValue() public {
    }

    function mintBasket(uint _mintAmount) public {
    }

    function depositCollateral(uint _collateralAmount) public {
    }

    function repayBorrowed(uint _repayAmount) public {
    }

    function withdraw(uint _withdrawAmount) public {
    }

}
