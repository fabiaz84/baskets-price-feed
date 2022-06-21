pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/Test.sol";
import {IOracle} from "../Interfaces/IOracle.sol";
import {IComptroller} from "../Interfaces/IComptroller.sol";
import {ICToken} from "../Interfaces/ICToken.sol";
import {Constants} from "../../test/Constants.sol";
import {MarketsTestingSuite} from "../../test/MarketsTestingSuite.sol";
import {BasketsPriceFeed} from "../BasketsPriceFeed.sol";

interface Cheats {
    function deal(address who, uint256 amount) external;
    function startPrank(address sender) external;
    function stopPrank() external;
}

contract bSTBLScript is Script, Test {

    BasketsPriceFeed public basketFeed;
    Constants public const;
    IOracle public oracle;
    IComptroller public unitroller; 
    Cheats public cheats;
    ICToken public bdSTBL;    

/*
    constructor(){
	cheats = Cheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        cheats.deal(address(this), 1000 ether);	
	cheats.deal(0x99E2D20ac8AF17B6e00F57F0ee46936F4A358B13, 1000 ether);
        const = new Constants();

	setProtocolContracts();
    }

    function setProtocolContracts() public {
    	oracle = IOracle(const.oracle());
        unitroller = IComptroller(const.unitroller());
    }
	*/
    function run() external {
	/*
        vm.startBroadcast();
	//Set Basket Price Feed
        basketFeed = new BasketsPriceFeed(const.bSTBL(), address(const.lendingRegistry()));
        basketFeed.setTokenFeed(const.RAI(), const.RAIFeed());
        basketFeed.setTokenFeed(const.DAI(), const.DAIFeed());
        basketFeed.setTokenFeed(const.USDC(), const.USDCFeed());
	vm.stopBroadcast();
	
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

        address bdSTBLAddress = deployCode("./out/CERC20Delegator.sol/CERC20Delegator.json", args);
	vm.stopBroadcast();

	bdSTBL = ICToken(bdSTBLAddress);
        cheats.startPrank(unitroller.admin());
        cheats.deal(unitroller.admin(), 1000 ether);

   	vm.startBroadcast();
        //Set Basket Price feed in Oracle
        oracle.setFeed(bdSTBL, address(basketFeed), 18);
        //Configure bdSTBL
        unitroller._supportMarket(bdSTBL);
        unitroller._setCollateralFactor(address(bdSTBL), 500000000000000000); //50%
        unitroller._setIMFFactor(bdSTBL, 40000000000000000);
        vm.stopBroadcast();
	
	cheats.stopPrank();

	vm.startBroadcast();
	bdSTBL._setReserveFactor(500000000000000000); //0.5 ether
        vm.stopBroadcast();
	*/
    }
}
