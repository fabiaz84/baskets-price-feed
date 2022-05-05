pragma solidity ^0.8.0;

import {ICToken} from "../src/Interfaces/ICToken.sol";
import {IRecipe} from "../src/Interfaces/IRecipe.sol";
import {ILendingRegistry} from "../src/Interfaces/ILendingRegistry.sol";
import {IBasketFacet} from "../src/Interfaces/IBasketFacet.sol";

contract Constants {

    /////////////////////////
    //        TOKENS       // 
    /////////////////////////

    ICToken public bdUSD = ICToken(0xc0601094C0C88264Ba285fEf0a1b00eF13e79347);
    ICToken public bdETH = ICToken(0xF635fdF9B36b557bD281aa02fdfaeBEc04CD084A);

    address public bSTBL = 0x5ee08f40b637417bcC9d2C51B62F4820ec9cF5D8;

    address public aRAI = 0xc9BC48c72154ef3e5425641a3c747242112a46AF;
    address public aFEI = 0x683923dB55Fead99A79Fa01A27EeC3cB19679cC3;
    address public cDAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address public aFRAX = 0xd4937682df3C8aEF4FE912A96A74121C0829E664;

    address public RAI = 0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919;
    address public FEI = 0x956F47F50A910163D8BF957Cf5846D573E7f87CA;
    address public DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;

    ILendingRegistry public lendingRegistry = ILendingRegistry(0x08a2b7D713e388123dc6678168656659d297d397);

    /////////////////////////
    //       Protocol      //
    /////////////////////////

    address public oralce = 0xEbdC2D2a203c17895Be0daCdf539eeFC710eaFd8;
    address public unitroller = 0x0Be1fdC1E87127c4fe7C05bAE6437e3cf90Bf8d8; //Comptroller interface
    address public usdcInterestRateModel = 0x681Cf55f0276126FAD8842133C839AB4D607E729;
    IRecipe public recipe = IRecipe(0x6C9c5fd51B95c7BF365955867268ce2EC25Deb5B);
    
}
