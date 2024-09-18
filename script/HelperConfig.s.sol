//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

struct NetworkConfig {
    address priceFeed;
}

contract HelperConfig is Script {
    NetworkConfig public myActiveNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    constructor() {
        if (block.chainid == 11155111) {
            myActiveNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            myActiveNetworkConfig = getEthMainnet();
        } else {
            myActiveNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sepoliaConfig;
    }

    function getEthMainnet() public pure returns (NetworkConfig memory) {
        NetworkConfig memory EthMainnet = NetworkConfig({priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
        return EthMainnet; // add return statement here
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        if (myActiveNetworkConfig.priceFeed != address(0)) {
            return myActiveNetworkConfig;
        }
        // if we want to deploy on local testnet, so we have to deploy on anvil using mocks

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});
        return anvilConfig;
    }
}
