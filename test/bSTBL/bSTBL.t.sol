pragma solidity ^0.8.0;

import {MarketsTestingSuite} from "../MarketsTestingSuite.sol";
import {Constants} from "../Constants.sol";
import {ICToken} from "../../src/Interfaces/ICToken.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {IComptroller} from "../../src/Interfaces/IComptroller.sol";
import {IOracle} from "../../src/Interfaces/IOracle.sol";
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
	uint _mintAmount = 1000000000000000000;
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

        //Depositing bSTBL as collateral
        testingSuite.depositCollateral(bdSTBL,bSTBLBalance,true);

	(,uint borrowingPowerBefore,) = IComptroller(const.unitroller()).getAccountLiquidity(address(this));
        testingSuite.borrowAssets(const.bdUSD(), borrowingPowerBefore);
        (,uint borrowingPowerAfter,) = IComptroller(const.unitroller()).getAccountLiquidity(address(this));
        uint bUSDBalance = IERC20(const.bUSD()).balanceOf(address(this));

	//We remove assets from the basket, which should directly impact the price of the asset
        uint amount = IERC20(const.aRAI()).balanceOf(bSTBL)/2;
	
	testingSuite.transferBasketAssets(const.aRAI(),address(this),amount);		

	//(,uint borrowingPowerAfter,) = IComptroller(const.unitroller()).getAccountLiquidity(address(this));

        //assertEq(borrowingPowerAfter);

    }

}
