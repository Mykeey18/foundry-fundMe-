// "t.sol" means this is a test file
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/Fundme.sol";
import {PriceConverter} from "../../src/PriceConverter.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    using PriceConverter for uint256;

    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; //i.e 10e18
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_FEE = 1;

    function setUp() external {
        // On our test the first thing that happens is the setup function and that is where we will deploy our contract
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public view {
        // we are testing if our minium USD is 5e18 from our FundMe contract
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWIthoutEnoughETH() public {
        vm.expectRevert(); // <- The next line after this one should revert! If not test fails.
        fundMe.fund(); // <- We send 0 value
    }

    function testFundUpdatesFundDataStrucutre() public {
        // we are testing if the `s_addressToAmountFunded` is updated correctly
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        // we are testing if the `funders` array is updated with `msg.sender`

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER); // we are testing if the funder is equal to USER
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert(); // we are expecting an error since the USER is not the owner but just a funder
        vm.prank(USER); // we are trying to make the USER withdraw
        fundMe.withdraw();
        // In a situation where we have two cheatcodes following each other above(vm.expect and vm.prank),
        // They would ignore each other and jump to the next, e.g/
        //when we call `vm.expectRevert();` that won't apply to `vm.prank(USER);`,
        //it will apply to the `withdraw` call instead. The same would have worked if these had been reversed
    }

    function testWithdarawWithSingleFunder() public funded {
        // we are testing if the withdraw will actually work
        // Methdology of working with test
        //Arrange, Act and Assert

        //Arrage
        uint256 startingOwnerBalance = fundMe.getOwner().balance; // we are getting the owner staring balance
        uint256 startingFundMeBalance = address(fundMe).balance; //we are getting the balance of the fundMe Contract which is the SEND_BALANCE(10 ether)
        // address(fundMe) means the address of the fundMe Contract

        //Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_FEE);
        vm.prank(fundMe.getOwner()); // cos only the owner can call the withdraw so we want to prank
        fundMe.withdraw(); // This is what we are testing(that is why it is put in the Act)

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0); // means ending Balance should be 0
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance); // means startingFundMeBalance + startingOwnerBalance should be equal to endingOwnerBalance
    }

    function testWithdrawFromMultipleFunders() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        //next we are creating a loop to craete new addresses for the numberOfFunders
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // everythime we go through a loop we add 1 to i
            // if you want to use numbers to generate address; those numbers have to be uint160
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
            //what we wrote above is that "many funders loop through the list and fund our fundMe contract"
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance; // we are getting the owner staring balance
        uint256 startingFundMeBalance = address(fundMe).balance; //we are getting the balance of the fundMe Contract which is the SEND_BALANCE(10 ether)
        // address(fundMe) means the address of the fundMe Contract

        //Act
        vm.startPrank(fundMe.getOwner()); // cos only the owner can call the withdraw so we want to prank
        fundMe.withdraw(); // This is what we are testing(that is why it is put in the Act)
        vm.stopPrank(); // Anything between start and stop prank will be sent pretending by the owner(getOwner())

        //assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        //next we are creating a loop to craete new addresses for the numberOfFunders
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // everythime we go through a loop we add 1 to i
            // if you want to use numbers to generate address; those numbers have to be uint160
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
            //what we wrote above is that "many funders loop through the list and fund our fundMe contract"
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance; // we are getting the owner staring balance
        uint256 startingFundMeBalance = address(fundMe).balance; //we are getting the balance of the fundMe Contract which is the SEND_BALANCE(10 ether)
        // address(fundMe) means the address of the fundMe Contract

        //Act
        vm.startPrank(fundMe.getOwner()); // cos only the owner can call the withdraw so we want to prank
        fundMe.cheaperWithdraw(); // This is what we are testing(that is why it is put in the Act)
        vm.stopPrank(); // Anything between start and stop prank will be sent pretending by the owner(getOwner())

        //assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }

    function testPrintStorageData() public view {
        for (uint256 i = 0; i < 3; i++) {
            bytes32 value = vm.load(address(fundMe), bytes32(i));
            //we are using vm.load so that we can load tghe value found in the providedstorage slot of the provided address
            console.log("Vaule at location", i, ":");
            console.logBytes32(value);
        }
        console.log("PriceFeed address:", address(fundMe.getPriceFeed()));
    }
}
