pragma solidity ^0.8.0;

import {ICToken} from "./ICToken.sol";

interface IComptroller{

    function _setCollateralFactor(ICToken cToken, uint newCollateralFactorMantissa) external returns (uint);

    function _setIMFFactor(ICToken cToken, uint newimfFactorMantissa) external returns (uint);

    function _supportMarket(ICToken cToken) external returns (uint);

    function admin() external view returns(address);
}
