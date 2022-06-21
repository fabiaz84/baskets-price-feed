pragma solidity ^0.8.0;

interface IAAVE{
    function deposit(address underlyignAsset, uint256 _amount, address _tokenHolder, uint16 referralCode) external;

    function withdraw(address underlyignAsset, uint256 _amount, address _tokenHolder) external;
}