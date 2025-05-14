// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

/*
* @title OracleLib
* @author 0xJund
* @notice This library is used to check the ChainLink Oracle for stale data.
* If a price is stale, the function will revert and render the DSCEngine unsuable - by design
* We want DSCEngine to freeze if the prices become stale
*/

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library OracleLib {

    error Oraclelib__StalePrice();
    uint256 private constant TIMEOUT = 3 hours;

    function staleCheckLatestRoundData(AggregatorV3Interface priceFeed) public view returns(uint80, int256, uint256, uint256, uint80) {
       (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();

    uint256 secondsSince = block.timestamp - updatedAt;
    if(secondsSince > TIMEOUT) revert Oraclelib__StalePrice();
    return (roundId, answer, startedAt, updatedAt, answeredInRound); 
    }
}
