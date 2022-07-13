pragma solidity ^0.8.1;

import "forge-std/Script.sol";
import "forge-std/Test.sol";
import {IOracle} from "../Interfaces/IOracle.sol";
import {IComptroller} from "../Interfaces/IComptroller.sol";
import {ICToken} from "../Interfaces/ICToken.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {IRecipe} from "../Interfaces/IRecipe.sol";
import {Constants} from "../../test/Constants.sol";
import {MarketsTestingSuite} from "../../test/MarketsTestingSuite.sol";
import {BasketsPriceFeed} from "../BasketsPriceFeed.sol";

interface Cheats {
    function deal(address who, uint256 amount) external;
    function startPrank(address sender) external;
    function stopPrank() external;
}

contract bSTBLScript is Script {

    BasketsPriceFeed public basketFeed;
    Constants public const;
    IOracle public oracle;
    IComptroller public unitroller; 
    Cheats public cheats;
    ICToken public bdSTBL;  

    event log_named_uint(string key, uint val);
    event log_named_address(string key, address val);


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
	
    function run() external {
        
        vm.startBroadcast();
        //Set Basket Price Feed
        basketFeed = new BasketsPriceFeed(const.bSTBL(), address(const.lendingRegistry()));
        basketFeed.setTokenFeed(const.RAI(), const.RAIFeed());
        basketFeed.setTokenFeed(const.DAI(), const.DAIFeed());
        basketFeed.setTokenFeed(const.USDC(), const.USDCFeed());
        vm.stopBroadcast();
    
        //Deploy dbToken contract for bSTBL
        bytes memory dbTokenDeployArgs = abi.encode(address(const.bSTBL()),
            address(0x0Be1fdC1E87127c4fe7C05bAE6437e3cf90Bf8d8),
            address(0x681Cf55f0276126FAD8842133C839AB4D607E729),
            200000000000000000,
            "bao deposited bSTBL",
            "bdSTBL",
            8,
            address(0xDb3401beF8f66E7f6CD95984026c26a4F47eEe84),
            ""
        );
        bytes memory bytecode = abi.encodePacked(vm.getCode("./marketsCode/CERC20Delegator.sol/CERC20Delegator.json"), dbTokenDeployArgs);
        address bdSTBLAddress;
        vm.startBroadcast();
        assembly {
            bdSTBLAddress := create(0, add(bytecode, 0x20), mload(bytecode))
        }
	    vm.stopBroadcast();
        require(
            bdSTBLAddress != address(0),
            "Test deployCode(string,bytes): Deployment failed."
        );
        
	    bdSTBL = ICToken(bdSTBLAddress);

        emit log_named_address("bdSTBL Address: ", bdSTBLAddress);
/*
        cheats.startPrank(unitroller.admin());
        cheats.deal(unitroller.admin(), 1000 ether);
        
        
        //Set Basket Price feed in Oracle
        oracle.setFeed(bdSTBL, address(basketFeed), 18);
        
        //Configure bdSTBL
        unitroller._supportMarket(bdSTBL);
        unitroller._setCollateralFactor(address(bdSTBL), 500000000000000000); //50%
        unitroller._setIMFFactor(bdSTBL, 40000000000000000);
	
        cheats.stopPrank();
        
        vm.startBroadcast();
        bdSTBL._setReserveFactor(500000000000000000); //0.5 ether
        vm.stopBroadcast();
        
        //Mint bSTBL to script executor

        address bSTBL = const.bSTBL();
        IRecipe recipe = IRecipe(const.recipe());
        uint256 mintPrice = recipe.getPriceEth(bSTBL, 100 ether);
        cheats.startPrank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        //Mint Basket tokens
        recipe.toBasket{value: mintPrice}(bSTBL, 100 ether);
        cheats.stopPrank();

        
        emit log_named_uint("bSTBL Balance: ", IERC20(bSTBL).balanceOf(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));*/
    }
}
