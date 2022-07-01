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
import {IFeed} from "../src/Interfaces/IFeed.sol";
import {IbUSD} from "../src/Interfaces/IbUSD.sol";
import {ILendingLogic} from "../src/Interfaces/ILendingLogic.sol";
import {ILendingManager} from "../src/Interfaces/ILendingManager.sol";
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
        setBasketsPriceFeeds();
	    createBasketMarket();
    }

    function setProtocolContracts() public {
    	oracle = IOracle(const.oracle());
        unitroller = IComptroller(const.unitroller());
    }

    function setBasketsPriceFeeds() public {
	//Deploy BasketCompatible Oracle
        basketFeed = new BasketsPriceFeed(const.bSTBL(), address(const.lendingRegistry()));
        basketFeed.setTokenFeed(const.RAI(), const.RAIFeed());
        basketFeed.setTokenFeed(const.DAI(), const.DAIFeed());
        basketFeed.setTokenFeed(const.USDC(), const.USDCFeed());
    }

    function createBasketMarket() public {

        bytes memory args = abi.encode(address(const.bSTBL()),
                address(0x0Be1fdC1E87127c4fe7C05bAE6437e3cf90Bf8d8),
                address(0x681Cf55f0276126FAD8842133C839AB4D607E729),
                200000000000000000,
                "bao deposited bSTBL",
                "bdSTBL",
                8,
                address(0xDb3401beF8f66E7f6CD95984026c26a4F47eEe84),
                ""
        );

        address bdSTBLAddress = deployCode("./marketsCode/CERC20Delegator.sol/CERC20Delegator.json", args);   
        bdSTBL = ICToken(bdSTBLAddress);

        cheats.startPrank(unitroller.admin());
        cheats.deal(unitroller.admin(), 1000 ether);
        
        //Set Basket Price feed in Oracle
        oracle.setFeed(bdSTBL, address(basketFeed), 18);
        //Configure bdSTBL
        unitroller._supportMarket(bdSTBL);
        unitroller._setCollateralFactor(address(bdSTBL), 500000000000000000); //50%
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
	    IRecipe recipe = IRecipe(const.recipe());
        cheats.startPrank(msg.sender);
        uint256 mintPrice = recipe.getPriceEth(_basket, _mintAmount);
        cheats.deal(address(this),mintPrice); 
        //Mint Basket tokens
	    recipe.toBasket{value: mintPrice}(_basket, _mintAmount);        
        cheats.stopPrank();
    }

    function depositCollateral(ICToken _dbToken, uint _collateralAmount, bool _joinMarket) public {
    	cheats.startPrank(msg.sender);
        IERC20 underlyingToken = IERC20(_dbToken.underlying());
        underlyingToken.approve(address(_dbToken),_collateralAmount);
        _dbToken.mint(_collateralAmount, _joinMarket);
        cheats.stopPrank(); 
   }

    function borrowAssets(ICToken _borrowAsset, uint _borrowAmount) public {
    	cheats.startPrank(msg.sender);
        _borrowAsset.borrow(_borrowAmount);
        cheats.stopPrank();
    }

    function repayBorrowed(ICToken _repayAsset, uint _repayAmount) public {
        cheats.startPrank(msg.sender);
        IERC20(_repayAsset.underlying()).approve(address(_repayAsset),_repayAmount);
        _repayAsset.repayBorrow(_repayAmount);	
        cheats.stopPrank();
    }

    function withdraw(ICToken _dbToken, uint _withdrawAmount, bool redeemUnderlying) public {
    	cheats.startPrank(msg.sender);
	    if(redeemUnderlying){
            _dbToken.redeemUnderlying(_withdrawAmount);
            return();
	    }
	    _dbToken.redeem(_withdrawAmount);
        cheats.stopPrank();
    }

    function transferBasketAssets(address _assetToMove, address _receiver, uint _amount) public {
    	cheats.startPrank(const.bSTBL());
        IERC20(_assetToMove).transfer(_receiver,_amount);
        cheats.stopPrank();
    }

    function getValueOfLendAsset(address _wrappedToken, uint _amount) public returns(uint) {
        bytes32 protocol = const.lendingRegistry().wrappedToProtocol(_wrappedToken);
        address logicContract = const.lendingRegistry().protocolToLogic(protocol);
        uint exchangeRate = ILendingLogic(logicContract).exchangeRate(_wrappedToken);
        _amount = _amount * exchangeRate / 1e18;
        uint price = IFeed(const.RAIFeed()).latestAnswer();	
        return(_amount * price / IFeed(const.RAIFeed()).decimals());
    }

    //Unlend bSTBL assets
    function unlendBasketAsset(address wrappedAsset,uint256 unlendAmount) public {
        cheats.startPrank(const.admin());
	    ILendingManager(const.bSTBLLendingManager()).unlend(wrappedAsset,unlendAmount);
        cheats.stopPrank();
    }

    function mintBaoUSD(address _receiver, uint _amount) public {
        cheats.startPrank(const.fed());
        IbUSD(const.bUSD()).mint(_receiver, _amount);
        cheats.stopPrank();
    }

    function liquidateUser(address _userGettingLiquidated, address _userLiquidating, uint _liquidationAmount, ICToken _borrowedCollateralToken, ICToken _receivedCollateralToken) public {
        cheats.startPrank(_userLiquidating);
        address underlyingAsset = _borrowedCollateralToken.underlying();
        IERC20(underlyingAsset).approve(address(_borrowedCollateralToken),_liquidationAmount);
        _borrowedCollateralToken.liquidateBorrow(_userGettingLiquidated, _liquidationAmount, _receivedCollateralToken);
        cheats.stopPrank();
    }

    receive() external payable{}

}
