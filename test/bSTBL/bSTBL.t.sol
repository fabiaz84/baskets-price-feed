pragma solidity ^0.8.0;

import {MarketsTestingSuite} from "../MarketsTestingSuite.sol";
import {Constants} from "../Constants.sol";
import {ICToken} from "../../src/Interfaces/ICToken.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {IComptroller} from "../../src/Interfaces/IComptroller.sol";
import {IOracle} from "../../src/Interfaces/IOracle.sol";
import {IChainLinkOracle} from "../../src/Interfaces/IChainLinkOracle.sol";
import {ICurve} from "../../src/Interfaces/ICurve.sol";
import {IAAVE} from "../../src/Interfaces/IAAVE.sol";
import "forge-std/Test.sol";
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";

contract bSTBLTest is DSTestPlus {

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
	uint _mintAmount = 10 ether;
        testingSuite.mintBasket(bSTBL,_mintAmount);
	uint bSTBLBalance = IERC20(bSTBL).balanceOf(address(this));
	assertEq(bSTBLBalance,_mintAmount);
	uint expectedCTokenBalance = (bSTBLBalance * 1e18) / bdSTBL.exchangeRateStored();
	//Depositing bSTBL as collateral
	testingSuite.depositCollateral(bdSTBL,bSTBLBalance,false);    
    	uint cTokenBalance = IERC20(address(bdSTBL)).balanceOf(address(this));
	bSTBLBalance = IERC20(bSTBL).balanceOf(address(this)); 
	//Check that the correct amount of collateral tokens was received
	assertEq(bSTBLBalance,uint(0));
	assertEq(cTokenBalance,expectedCTokenBalance);
    }

    function testCollateralizing() public {
        uint _mintAmount = 1000000000000000000;
        testingSuite.mintBasket(bSTBL,_mintAmount);
        uint bSTBLBalance = IERC20(bSTBL).balanceOf(address(this));

        //Depositing bSTBL as collateral
        testingSuite.depositCollateral(bdSTBL,bSTBLBalance,true);

	//get Borrowing power
	(,uint borrowingPower,) = IComptroller(const.unitroller()).getAccountLiquidity(address(this));
	//calc expected borrowing power
	uint expectedBorrowingPower = (IOracle(const.oracle()).getUnderlyingPrice(bdSTBL) * (_mintAmount / 2 )) / 1e18;
	
        assertLt(borrowingPower,expectedBorrowingPower+5);
    	assertGt(borrowingPower,expectedBorrowingPower-5);	
	//assertEq(borrowingPower,expectedBorrowingPower,"Actual Borrowing Power is not the same as the expected borrowing power");
    }

    function testBorrowing() public {
	uint _mintAmount = 1000000000000000000;
        testingSuite.mintBasket(bSTBL,_mintAmount);
        uint bSTBLBalance = IERC20(bSTBL).balanceOf(address(this));
        
        //Depositing bSTBL as collateral
        testingSuite.depositCollateral(bdSTBL,bSTBLBalance,true);

        (,uint borrowingPowerBefore,) = IComptroller(const.unitroller()).getAccountLiquidity(address(this));
        testingSuite.borrowAssets(const.bdUSD(), borrowingPowerBefore);
	(,uint borrowingPowerAfter,) = IComptroller(const.unitroller()).getAccountLiquidity(address(this));
        uint bUSDBalance = IERC20(const.bUSD()).balanceOf(address(this));        
        
        //get borrowingPower
        assertEq(borrowingPowerAfter,0);
        //check bUSD Balance
        assertEq(bUSDBalance,borrowingPowerBefore);
    }

    function testRedeeming() public {
         uint _mintAmount = 1000000000000000000;
        testingSuite.mintBasket(bSTBL,_mintAmount);
        uint bSTBLBalance = IERC20(bSTBL).balanceOf(address(this));

        //Depositing bSTBL as collateral
        testingSuite.depositCollateral(bdSTBL,bSTBLBalance,true);

        (,uint borrowingPowerBefore,) = IComptroller(const.unitroller()).getAccountLiquidity(address(this));
        testingSuite.borrowAssets(const.bdUSD(), borrowingPowerBefore);
        
	uint bUSDBalance = IERC20(const.bUSD()).balanceOf(address(this));
	
        testingSuite.repayBorrowed(const.bdUSD(), bUSDBalance);

	(,uint borrowingPower,uint debt) = IComptroller(const.unitroller()).getAccountLiquidity(address(this));
        
	uint expectedBorrowingPower = (IOracle(const.oracle()).getUnderlyingPrice(bdSTBL) * (_mintAmount / 2 )) / 1e18;

	//get borrowingPower
        assertEq(debt,0);
        
	//Borrowing power should be equal to the original depositing amount
	assertApproxEq(borrowingPower,expectedBorrowingPower,5);
    }

    function testWithdrawing() public {
    	uint _mintAmount = 1000000000000000000;
        testingSuite.mintBasket(bSTBL,_mintAmount);
        uint bSTBLBalance = IERC20(bSTBL).balanceOf(address(this));

        //Depositing bSTBL as collateral
        testingSuite.depositCollateral(bdSTBL,bSTBLBalance,true);
	//Withdraw assets
	testingSuite.withdraw(bdSTBL, bSTBLBalance, true);
        uint afterWitdrawAmount = IERC20(bSTBL).balanceOf(address(this)); 
	(,uint borrowingPower,uint debt) = IComptroller(const.unitroller()).getAccountLiquidity(address(this)); 

	assertEq(afterWitdrawAmount,bSTBLBalance);
	assertEq(borrowingPower,0);
    }	

    function testLiquidation() public {
	uint _mintAmount = 1000000000000000000;
        testingSuite.mintBasket(bSTBL,_mintAmount);
        uint bSTBLBalance = IERC20(bSTBL).balanceOf(address(this));
	uint totalbSTBLBalance = IERC20(bSTBL).totalSupply();

        //Depositing bSTBL as collateral
        testingSuite.depositCollateral(bdSTBL,bSTBLBalance,true);
	uint256 bSTBLPrice = IOracle(const.oracle()).getUnderlyingPrice(bdSTBL);
	uint collateralValue = bSTBLBalance * bSTBLPrice / 1e18;
	
	//Borrow baoUSD
        (,uint borrowingPowerBefore,) = IComptroller(const.unitroller()).getAccountLiquidity(address(this));
        testingSuite.borrowAssets(const.bdUSD(), borrowingPowerBefore);
        (,,uint debtBefore) = IComptroller(const.unitroller()).getAccountLiquidity(address(this));

        //We remove assets from the basket, which should directly impact the price of the asset

        //testingSuite.unlendBasketAsset(const.aRAI(),100000 ether);
	uint raiAmount = IERC20(const.aRAI()).balanceOf(address(const.bSTBL())) / 2;
	//emit log_named_uint("RAI_AMOUNT_TEST: ", raiAmount);
	//emit log_named_uint("RAI_PRICE_TEST: ", uint256(IChainLinkOracle(const.RAIFeed()).latestAnswer()));
	testingSuite.transferBasketAssets(const.aRAI(),address(this),raiAmount);		
        testingSuite.basketFeed().latestAnswerView();
        uint raiValue = raiAmount * uint256(IChainLinkOracle(const.RAIFeed()).latestAnswer()) / 1e8;

	uint bSTBLPriceAfter = IOracle(const.oracle()).getUnderlyingPrice(bdSTBL);
	//ToDo: check that this is equal to value of RAI removed
	uint bSTBLValueLoss = (totalbSTBLBalance * bSTBLPrice / 1e18) - (totalbSTBLBalance * bSTBLPriceAfter / 1e18);

	(,uint borrowingPowerAfter,uint debtAfter) = IComptroller(const.unitroller()).getAccountLiquidity(address(this));

	uint256 borrowingPowerValueLoss = debtAfter * 1e18 / borrowingPowerBefore;
	emit log_named_uint("totalbSTBLBalance: ", totalbSTBLBalance);
	emit log_named_uint("bSTBLPrice: ",bSTBLPrice);
	emit log_named_uint("bSTBLPriceAfter: ", bSTBLPriceAfter);
	emit log_named_uint("bSTBLValueLoss: ", bSTBLValueLoss);
	emit log_named_uint("rai Value removed: ", raiValue);
	uint256 totalbSTBLValue = totalbSTBLBalance * bSTBLPrice / 1e28;

	//Check that borrowing power decreased by the correct amount
	//assertApproxEq(bSTBLValueLoss,borrowingPowerValueLoss,4);
	
	//Repay Borrow
    }

    function testRebalancing() public {
	uint256 _mintAmount = 10 ether;

        testingSuite.mintBasket(bSTBL,_mintAmount);
        uint bSTBLBalance = IERC20(bSTBL).balanceOf(address(this));
        uint totalbSTBLBalance = IERC20(bSTBL).totalSupply();
        emit log_named_uint("Chackpoint : ", 0);
        //Depositing bSTBL as collateral
        testingSuite.depositCollateral(bdSTBL,bSTBLBalance,true);
        uint256 bSTBLPrice = IOracle(const.oracle()).getUnderlyingPrice(bdSTBL);
        uint collateralValue = bSTBLBalance * bSTBLPrice / 1e18;
        emit log_named_uint("Chackpoint : ", 1);
        (,uint borrowingPowerBefore,) = IComptroller(const.unitroller()).getAccountLiquidity(address(this));
        testingSuite.borrowAssets(const.bdUSD(), borrowingPowerBefore);
        uint bUSDBalance = IERC20(const.bUSD()).balanceOf(address(this));
        (,,uint debtBefore) = IComptroller(const.unitroller()).getAccountLiquidity(address(this));
        uint raiAmount = IERC20(const.aRAI()).balanceOf(address(const.bSTBL())) / 2;
        emit log_named_uint("Chackpoint : ", 2);
        //We remove assets from the basket, which should directly impact the price of the asset
        testingSuite.transferBasketAssets(const.aRAI(),address(this),raiAmount);
        emit log_named_uint("Chackpoint : ", 3);
        //Unlend aRAI
        IAAVE(const.aaveLendingPool()).withdraw(const.RAI(),raiAmount,address(this));
        emit log_named_uint("Chackpoint : ", 4);
        //Swap RAI for DAI
        uint RAIBalance = IERC20(const.RAI()).balanceOf(address(this));
        IERC20(const.RAI()).approve(const.raiCurvePool(),RAIBalance);
        emit log_named_uint("Chackpoint : ", 5);
        ICurve(const.raiCurvePool()).exchange_underlying(0, 1, RAIBalance, 0);	
        emit log_named_uint("Chackpoint : ", 6);
        uint DAIBalance = IERC20(const.DAI()).balanceOf(address(this));
        emit log_named_uint("DAI Balance : ", DAIBalance);

        //Lend DAI -> aDAI
        IERC20(const.DAI()).approve(const.DAI(), DAIBalance);
        emit log_named_uint("Chackpoint : ", 7);
        IAAVE(const.aaveLendingPool()).deposit(const.DAI(), DAIBalance, address(this), 0);
        emit log_named_uint("Chackpoint : ", 8);
        IERC20(const.aDAI()).transfer(const.bSTBL(),DAIBalance);
        emit log_named_uint("Chackpoint : ", 9);

        uint256 bSTBLPriceAfterRebalance = IOracle(const.oracle()).getUnderlyingPrice(bdSTBL);
        emit log_named_uint("bSTBL Price before Rebalance: ", bSTBLPrice);
	emit log_named_uint("bSTBL Price after Rebalance: ", bSTBLPriceAfterRebalance);
    }

    receive() external payable{}
}
