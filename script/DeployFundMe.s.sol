//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/Fundme.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // before startBroadcast --> Not a real trx and doesn't cost gas
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.myActiveNetworkConfig();

        // after startBroadcast --> Real trx and cost gas
        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}

// * **Unit tests**: Focus on isolating and testing individual smart contract functions or functionalities.
// * **Integration tests**: Verify how a smart contract interacts with other contracts or external systems.
// * **Forking tests**: Forking refers to creating a copy of a blockchain state at a specific point in time. This copy, called a fork, is then used to run tests in a simulated environment.
// * **Staging tests**: Execute tests against a deployed smart contract on a staging environment before mainnet deployment
