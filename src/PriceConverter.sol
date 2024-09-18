// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // Address 0x694AA1769357215DE4FAC081bf1f309aDC325306
        //ABI
        // The `AggregatorV3Interface` includes the `latestRoundData` function, which retrieves the latest cryptocurrency price from the specified contract
        // This interface requires the address of the Data Feed contract deployed on the Sepolia Network

        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // let's say we want to convert 1 Eth and 1 Eth price is 2000*10e18
        uint256 ethPrice = getPrice(priceFeed);
        // then we multiply 1eth(1 * 10e18) * eth price 2000 * 10e18
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        // we divide the result by 1e18 to get the answer in usd(i.e $2000*10e18)
        return ethAmountInUsd;
    }
}
