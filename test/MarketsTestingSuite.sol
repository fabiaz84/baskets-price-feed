pragma solidity ^0.8.0;

import {Constants} from "./Constants.sol";
import {BasketsPriceFeed} from "../src/BasketsPriceFeed.sol";
import {IBasketFacet} from "../src/Interfaces/IBasketFacet.sol";
import {ICToken} from "../src/Interfaces/ICToken.sol";
import {IRecipe} from "../src/Interfaces/IRecipe.sol";

contract MarketsTestingSuite {

    //MARKETS CONTRACTS
    BasketsPriceFeed public basketFeed;
    //Oracle public oracle;

    Constants const; 

    function setUp() public{
        const = new Constants();

        deployBasketsPriceFeed();
	createBasketMarket();
    }

    function deployBasketsPriceFeed() public {
	//Deploy BasketCompatible Oracle
        basketFeed = new BasketsPriceFeed(const.bSTBL(), address(const.lendingRegistry()));
    }

    function createBasketMarket() public {
    	//Deploy bdbUSD
   	//Use existing interest rate model
        //Set Basket Price feed in Oracle
	//Set Factors/Configure
    }

    function getBasketValue() public {
    }

    function getBorrowedAmountValue() public {
    }

    function mintBasket(uint _mintAmount) public {
	IRecipe recipe = const.recipe();
	address bSTBL = const.bSTBL();

        //GET Best DEX Prices
	(uint256 mintPrice, uint16[] memory dexIndices) = recipe.getPricePie(bSTBL, _mintAmount);
	payable(address(recipe)).transfer(mintPrice);
	recipe.toPie(bSTBL, _mintAmount, dexIndices);        
	//IBasketFacet(const.bSTBL()).;
    }

    function depositCollateral(uint _collateralAmount) public {
    }

    function repayBorrowed(uint _repayAmount) public {
    }

    function withdraw(uint _withdrawAmount) public {
    }

}
