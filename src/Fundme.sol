// Get funds from users
// Withraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error FundMe_NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;
    // the main reason why we are adding constant and immutable(line 36) is to optimize gas and be better developer

    uint256 public myValue = 1;

    function fund() public payable {
        // to enable a function to receive a native blockchain token such as Ethereum, it needs to be marked as payable
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "you no get money"); // it means the user has to spent at least $5
        // If we want a function to fail under certain conditions, we can use the `require` statement
        // since msg.value is measured in eth/gwei and the minimu is $5 then we have to introduce oracle/cahinlink
        s_funders.push(msg.sender); // The `msg.sender' refers to the address that initiates the transaction
        s_addressToAmountFunded[msg.sender] += msg.value; // associates each funder's address with the total amount they have contributed
            // `+=`: adds a value to an existing one. `x = x + y` is equivalent to `x += y`
    }

    // to determine the price of eth in usd we need a fn to do that

    // if we want to keeo track of those that send us funds, we can create a list/array of that

    address[] private s_funders; //priveate is gas efficient compared to public
    mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded;

    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    constructor(address priceFeed) {
        // we can modify this in a scenerio we have to deploy this contract to any network and not just sepolia
        //this function get called once immediately this contract is deployed
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 funderLength = s_funders.length; // we are reading from storage only one time compared to "for" under withdraw fn
        for (uint256 funderIndex = 0; funderIndex < funderLength; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0; // this is now a memory variable which cost less gas
        }
        // to reset the array
        s_funders = new address[](0);
        (bool callSucess,) = payable(msg.sender).call{value: address(this).balance}("");
        // The `call` function returns two variables: a boolean for success or failure, and a byte object which stores returned data if any
        require(callSucess, "call failed");
    }

    function withdraw() public onlyOwner {
        // since we add "onlyOwner" it will execute line 63 first(the owner only has access) then 64 "-;" which means it should execue the rest(line 46-48)
        // writing line 64 first before 63 has the opposite meaning of above

        // for (/* staring index, ending index, step amount */) (format for writing for-loops
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            // "++" means itself + 1 e.g. `funderIndex++`: shorthand for `funderIndex = funderIndex + 1`

            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // to reset the array
        s_funders = new address[](0);
        // There are three diff ways of withdrawing i.e transfer, send and call
        // call is the modern way of withdrawing/ sending eth out
        (bool callSucess,) = payable(msg.sender).call{value: address(this).balance}("");
        // The `call` function returns two variables: a boolean for success or failure, and a byte object which stores returned data if any
        require(callSucess, "call failed");
    }

    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Na owner get the money!");
        // line 67 and 69 are the same but line 69 is more gas efficient
        if (msg.sender != i_owner) {
            revert FundMe_NotOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
        // Explainer from: https://solidity-by-example.org/fallback/
        // Ether is sent to contract
        //      is msg.data empty?
        //          /   \
        //         yes  no
        //         /     \
        //    receive()?  fallback()
        //     /   \
        //   yes   no
        //  /        \
        //receive()  fallback()
    }

    /**
     * view/pure fuunctions (Getters
     */
    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
