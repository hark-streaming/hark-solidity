// SPDX-License-Identifier: GPL-3.0
    
pragma solidity >=0.4.22 <0.9.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "remix_accounts.sol";
import "../HarkPlatformToken.sol";
import "../HarkPlatformToken.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract testSuite {

    HarkPlatformToken platform;

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function construction() public {
        // Here should instantiate tested contract
        platform = new HarkPlatformToken(100);
        
        Assert.equal(uint(platform.tax()), uint(100), "Tax isn't set properly.");
        Assert.equal(bool(true), bool(platform.balanceOf(address(this)) > 0), "No initial mint given to the creator.");
    }

    function checkSetTaxRate() public {
        platform.setTax(150);
        Assert.equal(uint(150), uint(platform.tax()), "Tax rate should be 150 after setting it to 150.");
        
        platform.setTax(30000);
        Assert.equal(uint(150), uint(platform.tax()), "Tax rate should still be 150 after setting it to 150.");
        
        platform.setTax(100);
        Assert.equal(uint(100), uint(platform.tax()), "Tax rate should be 100 after setting it to 100.");
    }

    function checkSuccess2() public pure returns (bool) {
        // Use the return value (true or false) to test the contract
        return true;
    }
    
    function checkFailure() public {
        Assert.equal(uint(1), uint(2), "1 is not equal to 2");
    }

    /// Custom Transaction Context
    /// See more: https://remix-ide.readthedocs.io/en/latest/unittesting.html#customization
    /// #sender: account-1
    /// #value: 100
    function checkSenderAndValue() public payable {
        // account index varies 0-9, value is in wei
        Assert.equal(msg.sender, TestsAccounts.getAccount(1), "Invalid sender");
        Assert.equal(msg.value, 100, "Invalid value");
    }
}
