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
        
        Assert.equal(uint(platform.tax()), uint(100), "Tax isn't set properly upon construction.");
        Assert.equal(bool(true), bool(platform.balanceOf(address(this)) > 0), "No initial mint given to the creator.");
    }

    function checkSetTaxRate() public {
        platform.setTax(150);
        Assert.equal(uint(150), uint(platform.tax()), "Tax rate should be 150 after setting it to 150.");
        
        platform.setTax(100);
        Assert.equal(uint(100), uint(platform.tax()), "Tax rate should be 100 after setting it to 100.");
    }
    
    function checkSetMinimumGovernanceTokenRequirement() public {
        platform.setMinimumSupplyForNomination(1000);
        Assert.equal(uint(1000), uint(platform.minimumSupplyForNomination()), "MinimumSupplyForNomination should be 1000 after setting it to 1000.");
        
        platform.setMinimumSupplyForNomination(5000);
        Assert.equal(uint(5000), uint(platform.minimumSupplyForNomination()), "MinimumSupplyForNomination should be 5000 after setting it to 5000.");
    }

    function checkCreatingElection() public {
        Assert.equal(platform.getElectionCount(), 0, "Election count should be 0 when creating.");

        // created the first election        
        uint ending = block.timestamp + 50;
        uint newVoteElection = platform.createVote(ending);

        // checks that everything about the first election was right
        Assert.equal(newVoteElection, 0, "First election id was not 0.");
        Assert.equal(platform.getElectionCount(), 1, "Election count was not 1 after adding the first stream.");
        Assert.equal(false, platform.electionHasEnded(newVoteElection), "New election should not have ended.");
        Assert.equal(0, platform.getNomineeCount(0), "New election should not have any nominees before adding them.");
        
        // 
    }
}