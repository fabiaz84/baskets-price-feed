// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IRateProvider.sol";
import "./interfaces/IbETHPriceFeed.sol";


/**
 * @title Chainlink Rate Provider
 * @notice Returns a Chainlink price feed's quote for the provided currency pair
 * @dev This rate provider is a simplification of ChainlinkReistryRateProvider which is fixed to a particular pricefeed.
 *      This is expected to be used in environments where the Chainlink registry is not available.
 */
contract bETHPriceFeed is IRateProvider {
    AggregatorV3Interface public immutable pricefeed;
	IbETHPriceFeed public immutable bETHPriceFeed;

    // Rate providers are expected to respond with a fixed-point value with 18 decimals
    // We then need to scale the price feed's output to match this.
    uint256 internal immutable _scalingFactor;
	uint256 internal immutable _scalingFactorbETH;

    /**
     * @param feed - The Chainlink price feed contract
     */
    constructor(address feed, address bETHfeed) {
        pricefeed = AggregatorV3Interface(feed);
		bETHPriceFeed = IbETHPriceFeed(bETHfeed);
        _scalingFactor = 10**SafeMath.sub(18, feed.decimals());
		_scalingFactorbETH = 10**SafeMath.sub(18, bETHfeed.decimals());
    }

    /**
     * @return the value of the quote currency in terms of the base currency
     */
    function getRate() external view override returns (uint256 rate) {
        (, int256 price, , , ) = pricefeed.latestRoundData();
        require(price > 0, "Invalid price rate response");
		bethprice = bETHPriceFeed.latestAnswer();
        require(bethprice > 0, "Invalid price rate response");
        rate = (uint256(price) * _scalingFactor).div(uint256(bethprice) * _scalingFactorbETH);
        return rate
    }
}