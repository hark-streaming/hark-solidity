pragma solidity ^0.8.3;

import "./HarkGovernanceToken.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol";

contract GovernanceElection is Ownable {
    
    //#region --- STRUCTS ---
    
    // represents a user's vote
    struct RegisteredVote {
        // whether or not the user has voted
        bool hasVoted;
        
        // the option that the user voted for
        uint8 option;
        
        // the number of tokens that the user voted with at time of voting
        uint32 tokenVote;
    }
    
    // represents an election for the body
    struct Election {
        // number of vote options
        uint8 options;
        
        // total number of votes in each category (and thus voters) in this election
        uint24[] votes;
        
        // the number of token votes in each category
        uint32[] votesToken;
        
        // the end of the election
        uint deadline;
        
        // the people who have voted
        mapping(address => RegisteredVote) voteRegister;
    }
    
    //#endregion
    
    
    
    //#region --- DATA, MODIFIERS, CONSTRUCTOR ---
    
    // governing entity info
    HarkGovernanceToken public token;

    // election info
    uint32 numElections;
    mapping(uint32 => Election) public elections;

    constructor(HarkGovernanceToken _token) {
        require(_token.owner() == msg.sender);
        token = _token;
    }
    
    //#endregion
    
    
    
    //#region --- GETTERS ---
    
    // returns the number of elections published so far
    function getElectionCount() public view returns(uint) { return numElections; }
    
    // returns true if election has ended, false if not
    function electionHasEnded(uint _electId) public view returns(bool) { return elections[_electId].deadline < block.timestamp; }
    
    // returns the number of options based on the election
    function getOptions(uint _electId) public view returns(uint8) {
        require(_electId < getElectionCount());
        return elections[_electId].options;
    }
    
    // gets the number of voters per option
    function getVotes(uint _electId) public view returns(uint24[] memory) {
        require(_electId < getElectionCount());
        return elections[_electId].votes;
    }
    
    // gets the number of tokens allocated per option
    function getVotesToken(uint _electId) public view returns(uint32[] memory) {
        require(_electId < getElectionCount());
        return elections[_electId].votesToken;
    }
    
    // gets relevant election data of a specific election
    function getElection(uint _electId) public view returns(uint8 options, uint24[] memory votes, uint32[] memory votesToken, uint deadline) {
        options = elections[_electId].options;
        votes = elections[_electId].votes;
        votesToken = elections[_electId].votesToken;
        deadline = elections[_electId].deadline;
    }
    
    //#endregion
    
    
    
    //#region --- SETTERS ---
    
    // throws back tfuel if someone tries to directly send it here
    fallback () external { revert("Contract doesn't take gas directly."); }
    
    // adds or changes a user's vote in a specific election
    function vote(uint8 _option, uint _electId) public {
        require(_electId < getElectionCount(), "Bad election ID.");
        require(0 <= _option && _option < elections[_electId].options, "Bad vote option.");
        require(!electionHasEnded(_electId), "Election has ended.");

        // retrieves the token amount of the voter
        uint32 voterTokens = uint32(token.balanceOf(msg.sender));
        
        // changes if the user has already voted
        if(elections[_electId].voteRegister[msg.sender].hasVoted) {
            // removes previous vote values
            uint8 previousOption = elections[_electId].voteRegister[msg.sender].options;
            elections[_electId].votes[previousOption] -= 1;
            elections[_electId].votesToken[previousOption] -= elections[_electId].voteRegister[msg.sender].tokenVote;
        }
        
        // adds voter record
        elections[_electId].voteRegister[msg.sender] = RegisteredVote(true, _option, voterTokens);

        // adds to total sum
        elections[_electId].votes[_option] += 1;
        elections[_electId].votesToken[_option] += voterTokens;
    }
    
    // creates a new election & returns its id
    function createVote(uint8 _optionCount, uint _deadline) onlyOwner public returns(uint) {
        elections.push(Election(_optionCount, new uint24[](_optionCount), new uint32[](_optionCount), _deadline));
        return getElectionCount() - 1;
    }
    
    // kills the contract to free up space
    function kill() onlyOwner public { selfdestruct(owner); }
    
    //#endregion
    
}
