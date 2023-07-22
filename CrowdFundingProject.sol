// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract CrowdFundingProject {
    mapping(address => uint256) public addressToContribution;
    //address --> contribution made by an address
    address public manager;
    //to store the address of the person/organization which invokes the contract
    uint256 public minimumContribution;
    //lower limit of contribution
    uint256 public deadLine;
    uint256 public target;
    uint256 public raisedAmount;
    uint256 public noOfContributors;

    //Details of a request
    struct Request {
        string description;
        address payable recipent;
        uint256 value;
        bool completed;
        uint256 noOfVoters;
        mapping(address => bool) voters;
    }
    mapping(uint256 => Request) public requests;
    //id of a request --> request
    uint256 public numRequests;

    //invoked by manager
    constructor(uint256 _target, uint256 _deadLine) {
        target = _target;
        deadLine = block.timestamp + _deadLine;
        minimumContribution = 100 wei;
        manager = msg.sender;
    }

    //to take contributions
    function spendEth() public payable {
        require(block.timestamp < deadLine, "Deadline has passed");
        require(
            msg.value >= minimumContribution,
            "Minimum contribution limit not met"
        );

        if (addressToContribution[msg.sender] == 0) {
            noOfContributors++;
        }
        addressToContribution[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    //to output the current balance
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    //refund when requested if deadline and target not met
    function refund() public {
        require(
            block.timestamp > deadLine && raisedAmount < target,
            "Not eligible"
        );
        require(addressToContribution[msg.sender] > 0);
        address payable user = payable(msg.sender);
        user.transfer(addressToContribution[msg.sender]);
        addressToContribution[msg.sender] = 0;
    }

    //modifier for createRequests function
    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can call this function");
        _;
    }
    
    //create a new request
    function createRequests(
        string memory _description,
        address payable _recipent,
        uint256 _value
    ) public onlyManager {
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description = _description;
        newRequest.recipent = _recipent;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }

    //when someone requests to vote
    function voteRequest(uint256 _requestNo) public {
        require(
            addressToContribution[msg.sender] > 0,
            "You must be a contributor"
        );
        Request storage thisRequest = requests[_requestNo];
        require(
            thisRequest.voters[msg.sender] == false,
            "You have already voted"
        );
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    //make payment if request holds true 
    function makePayment(uint256 _requestNo) public onlyManager {
        require(raisedAmount >= target);
        Request storage thisRequest = requests[_requestNo];
        require(
            thisRequest.completed == false,
            "The request has been completed"
        );
        require(
            thisRequest.noOfVoters > noOfContributors / 2,
            "Majority does not agree"
        );
        thisRequest.recipent.transfer(thisRequest.value);
        thisRequest.completed = true;
    }
}
