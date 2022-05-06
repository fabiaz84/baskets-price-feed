pragma solidity ^0.8.0;

import {ICToken} from "./ICToken.sol";

interface IOracle {
    
    function setFeed(ICToken cToken_, address feed_, uint8 tokenDecimals_) external;

    function setFixedPrice(ICToken cToken_, uint price) external;

    function removeFixedPrice(ICToken cToken_) external;

    function getUnderlyingPrice(ICToken cToken_) external view returns (uint);

}

