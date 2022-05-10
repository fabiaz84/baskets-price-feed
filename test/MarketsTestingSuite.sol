pragma solidity ^0.8.0;

import {Constants} from "./Constants.sol";
import {BasketsPriceFeed} from "../src/BasketsPriceFeed.sol";
import {IBasketFacet} from "../src/Interfaces/IBasketFacet.sol";
import {ICToken} from "../src/Interfaces/ICToken.sol";
import {IRecipe} from "../src/Interfaces/IRecipe.sol";
import {IERC20Metadata} from "@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {IOracle} from "../src/Interfaces/IOracle.sol";
import {IComptroller} from "../src/Interfaces/IComptroller.sol";
import "forge-std/Test.sol";

interface Cheats {
    function deal(address who, uint256 amount) external;
    function startPrank(address sender) external;
    function stopPrank() external;
}

contract MarketsTestingSuite is Test {

    //MARKETS CONTRACTS
    BasketsPriceFeed public basketFeed;
    ICToken public bdSTBL;
    IOracle public oracle;
    IComptroller public unitroller;
    Constants public const; 
    Cheats public cheats;

    constructor(){
	cheats = Cheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        cheats.deal(address(this), 1000 ether);	

        const = new Constants();
	setProtocolContracts();
        deployBasketsPriceFeed();
	createBasketMarket();
    }

    function setProtocolContracts() public {
    	oracle = IOracle(const.oracle());
        unitroller = IComptroller(const.unitroller());
    }

    function deployBasketsPriceFeed() public {
	//Deploy BasketCompatible Oracle
        basketFeed = new BasketsPriceFeed(const.bSTBL(), address(const.lendingRegistry()));
    }

    function createBasketMarket() public {
    	//Deploy bdSTBL
	bytes memory args = abi.encode(const.bSTBL(),
            const.unitroller(),
            const.usdcInterestRateModel(),
            200000000000000000,
            "bao deposited bSTBL",
            "bdSTBL",
            8);

	bdSTBL = ICToken(deployCode("./bytecode/CErc20Delegator.json", args));

	cheats.startPrank(unitroller.admin());
	
 	//Set Basket Price feed in Oracle
	IOracle(const.oracle()).setFeed(bdSTBL, address(basketFeed), 18);
	
	//Configure bdSTBL
	emit log_named_uint("Checkpoint",0);
	unitroller._supportMarket(bdSTBL);
	emit log_named_uint("Checkpoint",0);
	unitroller._setCollateralFactor(bdSTBL, 500000000000000000); //50%
	unitroller._setIMFFactor(bdSTBL, 40000000000000000);
	cheats.stopPrank();
	bdSTBL._setReserveFactor(500000000000000000); //0.5 ether
    }

    function getBasketValue() public returns(uint){
	return(0);
    }

    function getBorrowedAmountValue() public returns(uint){
    	return(0);
    }

    function getBuyingPower() public returns(uint){
	return(0);
    }

    function mintBasket(address _basket, uint _mintAmount) public {
	emit log_named_uint("Checkpoint",0);
	emit log_named_address("Checkpoint",address(this));
	address btbka = const.bSTBL();
/*	IRecipe recipe = IRecipe(const.recipe());
	emit log_named_uint("Checkpoint",1);

        //GET Best DEX Prices
	(uint256 mintPrice, uint16[] memory dexIndices) = recipe.getPricePie(_basket, _mintAmount);
	//Mint Basket tokens
	payable(address(recipe)).transfer(mintPrice);
	recipe.toPie(_basket, _mintAmount, dexIndices);*/        
    }

    function depositCollateral(ICToken _dbToken, uint _collateralAmount, bool _joinMarket) public {
    	cheats.startPrank(msg.sender);
	IERC20 underlyingToken = IERC20(_dbToken.underlying());
	underlyingToken.approve(address(_dbToken),_collateralAmount);
	_dbToken.mint(_collateralAmount, _joinMarket);
   	cheats.stopPrank(); 
   }

    function borrowAssets(ICToken _borrowAsset, uint _borrowAmount) public {
    	_borrowAsset.borrow(_borrowAmount);
    }

    function repayBorrowed(ICToken _repayAsset, uint _repayAmount) public {
        cheats.startPrank(msg.sender);
	IERC20(_repayAsset.underlying()).approve(address(_repayAsset),_repayAmount);
	_repayAsset.repayBorrow(_repayAmount);	
        cheats.stopPrank();
    }

    function withdraw(ICToken _dbToken, uint _withdrawAmount, bool redeemUnderlying) public {
    	if(redeemUnderlying){
	    _dbToken.redeemUnderlying(_withdrawAmount);
	    return();
	}
	_dbToken.redeem(_withdrawAmount);
    }

}
