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
	
        assertApproxEq(borrowingPower,expectedBorrowingPower,5);
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

        //We remove assets from the basket, which directly impacts the price of bSTBL
        testingSuite.basketFeed().latestAnswerView();
	uint raiAmount = IERC20(const.aRAI()).balanceOf(address(const.bSTBL())) / 3;
	testingSuite.transferBasketAssets(const.aRAI(),address(this),raiAmount);

        //Check that borrowing power was reduced by the right amount		
        (,uint borrowingPowerAfter,uint debtAfter) = IComptroller(const.unitroller()).getAccountLiquidity(address(this));
        uint bSTBLPriceAfter = IOracle(const.oracle()).getUnderlyingPrice(bdSTBL);
        //% bSTBL price drop
        uint bSTBLValueLoss = bSTBLPriceAfter * 1e18 / bSTBLPrice;
        //% Borrowing power price drop
        uint borrowingPowerDelta = 1e18 - (((borrowingPowerAfter + debtAfter) * 1e18) / borrowingPowerBefore); 
        emit log_named_uint("bSTBLValueLoss: ", bSTBLValueLoss);
        emit log_named_uint("borrowingPowerDelta: ", borrowingPowerDelta);
        //Truncation in Comptroller leads to inaccuracies
        assertApproxEq(bSTBLValueLoss,borrowingPowerDelta,20);

        //ACTUAL LIQUIDATION
        uint amountToLiquidate = (const.bdUSD().borrowBalanceStored(address(this))/2)-1;
        testingSuite.mintBaoUSD(const.user1(), amountToLiquidate);
	testingSuite.liquidateUser(address(this), const.user1(), amountToLiquidate, const.bdUSD(), bdSTBL);
        (,,uint debtAfterLiquidation) = IComptroller(const.unitroller()).getAccountLiquidity(address(this));
        //Check that new debt is 0
        assertEq(debtAfterLiquidation, 0);
        //Check that received amount is liquidation factor * repaid amount
        uint receivedLiquidationReward = IERC20(address(bdSTBL)).balanceOf(const.user1());
        uint liquidaitonIncentive = IComptroller(const.unitroller()).liquidationIncentiveMantissa();
        (,uint CalcReceivedLiquidationReward) = IComptroller(const.unitroller()).liquidateCalculateSeizeTokens(address(const.bdUSD()), address(bdSTBL), amountToLiquidate);
        //Check that liquidation amount is correct
        assertEq(receivedLiquidationReward, CalcReceivedLiquidationReward - (CalcReceivedLiquidationReward * 2.8e16 /1e18));
        //emit log_named_uint("receivedLiquidationReward: ", receivedLiquidationReward);
        //emit log_named_uint("receivedLiquidationReward    : ", (bdSTBL.exchangeRateCurrent()*receivedLiquidationReward/1e18) * bSTBLPriceAfter / 1e18);
        //emit log_named_uint("amountToLiquidate               : ", amountToLiquidate); 
        //emit log_named_uint("receivedLiquidationReward       : ", receivedLiquidationReward);
        //emit log_named_uint("bSTBLPriceAfter                 : ", bSTBLPriceAfter);
        //emit log_named_uint("Exchange Rate                   : ", bdSTBL.exchangeRateCurrent());
        //emit log_named_uint("actualReceivedLiquidationReward : ", (receivedLiquidationReward * bdSTBL.exchangeRateCurrent() / 1e18) * bSTBLPriceAfter / 1e18);
        //emit log_named_uint("Profit                          : ", ((receivedLiquidationReward * bdSTBL.exchangeRateCurrent() / 1e18) * bSTBLPriceAfter / 1e18) - amountToLiquidate);
        //emit log_named_uint("Ratio                           : ", (((receivedLiquidationReward * bdSTBL.exchangeRateCurrent() / 1e18) * bSTBLPriceAfter / 1e18) - amountToLiquidate)*1e18/amountToLiquidate);
    }

    function testRebalancing() public {
	uint256 _mintAmount = 10 ether;

        testingSuite.mintBasket(bSTBL,_mintAmount);
        uint bSTBLBalance = IERC20(bSTBL).balanceOf(address(this));
        uint totalbSTBLBalance = IERC20(bSTBL).totalSupply();

        //Depositing bSTBL as collateral
        testingSuite.depositCollateral(bdSTBL,bSTBLBalance,true);
        uint256 bSTBLPrice = IOracle(const.oracle()).getUnderlyingPrice(bdSTBL);
        uint collateralValue = bSTBLBalance * bSTBLPrice / 1e18;

        (,uint borrowingPowerBefore,) = IComptroller(const.unitroller()).getAccountLiquidity(address(this));
        testingSuite.borrowAssets(const.bdUSD(), borrowingPowerBefore);
        uint bUSDBalance = IERC20(const.bUSD()).balanceOf(address(this));
        (,,uint debtBefore) = IComptroller(const.unitroller()).getAccountLiquidity(address(this));
        uint raiAmount = IERC20(const.aRAI()).balanceOf(address(const.bSTBL())) / 2;

        //Save aDAI and aRAI Balances before rebalancing for logging
        uint oldDAIBalance = IERC20(const.aDAI()).balanceOf(const.bSTBL());
        uint oldRAIBalance = IERC20(const.aRAI()).balanceOf(const.bSTBL());

        //We remove assets from the basket, which should directly impact the price of the asset
        testingSuite.transferBasketAssets(const.aRAI(),address(this),raiAmount);

        //Unlend aRAI
        IAAVE(const.aaveLendingPool()).withdraw(const.RAI(),raiAmount,address(this));

        //Swap RAI for DAI
        uint RAIBalance = IERC20(const.RAI()).balanceOf(address(this));
        IERC20(const.RAI()).approve(const.raiCurvePool(),RAIBalance);
        ICurve(const.raiCurvePool()).exchange_underlying(0, 1, RAIBalance, 0);	
        uint DAIBalance = IERC20(const.DAI()).balanceOf(address(this));

        //Lend DAI -> aDAI
        IERC20(const.DAI()).approve(const.aaveLendingPool(), DAIBalance);
        IAAVE(const.aaveLendingPool()).deposit(const.DAI(), DAIBalance, address(this), 0);
        
        //Transfer aDAI into bSTBL
        IERC20(const.aDAI()).transfer(const.bSTBL(),DAIBalance);

        uint256 bSTBLPriceAfterRebalance = IOracle(const.oracle()).getUnderlyingPrice(bdSTBL);
        emit log_named_uint("bSTBL Price before Rebalance: ", bSTBLPrice);
	emit log_named_uint("bSTBL Price after Rebalance: ", bSTBLPriceAfterRebalance);
        //uint newDAIBalance = IERC20(const.aDAI()).balanceOf(const.bSTBL());
        //uint newRAIBalance = IERC20(const.aRAI()).balanceOf(const.bSTBL());
        //emit log_named_uint("New aDAI Balance : ", newDAIBalance);
        //emit log_named_uint("Old aDAI Balance : ", oldDAIBalance);
        //emit log_named_uint("New RAI Balance : ", newRAIBalance);
        //emit log_named_uint("Old RAI Balance : ", oldRAIBalance);
    }

    receive() external payable{}
}
