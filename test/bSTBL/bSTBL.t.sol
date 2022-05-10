pragma solidity ^0.8.0;

import {MarketsTestingSuite} from "../MarketsTestingSuite.sol";
import {Constants} from "../Constants.sol";
import {ICToken} from "../../src/Interfaces/ICToken.sol";
import "forge-std/Test.sol";

contract bSTBLTest is Test {

    MarketsTestingSuite testingSuite;
    ICToken bdSTBL;
    address bSTBL;
    Constants const;

    function setUp() public{
	testingSuite = new MarketsTestingSuite();	
        const = new Constants();
	bdSTBL = testingSuite.bdSTBL();
    	bSTBL = const.bSTBL();
    }

    //"Minting" in the baskets markets context means depositing collateral and receiving dbTokens in return
    function testMinting() public {
	uint _mintAmount = 10;
        testingSuite.mintBasket(bSTBL,_mintAmount);
	//testingSuite.depositCollateral(bdSTBL,_mintAmount,false);
    }	
}
/*
function mintBasket(address _basket, uint _mintAmount) public {
        IRecipe recipe = const.recipe();

        //GET Best DEX Prices
        (uint256 mintPrice, uint16[] memory dexIndices) = recipe.getPricePie(_basket, _mintAmount);
        //Mint Basket tokens
        payable(address(recipe)).transfer(mintPrice);
        recipe.toPie(_basket, _mintAmount, dexIndices);
    }

    function depositCollateral(ICToken _dbToken, uint _collateralAmount, bool _joinMarket) public {
        cheats.startPrank(msg.sender);
        IERC20 underlyingToken = IERC20(_dbToken.underlying());
        underlyingToken.approve(address(_dbToken),_collateralAmount);
        _dbToken.mint(_collateralAmount, _joinMarket);
        cheats.stopPrank();
   }*/
