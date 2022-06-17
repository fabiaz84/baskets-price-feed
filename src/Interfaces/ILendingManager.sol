pragma solidity ^0.8.0;

interface ILendingManager{ 
    function unlend(address _wrapped, uint256 _amount) external;
}
