// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

contract CampaignFactory{
    address [] public deployedCampaigns;

    function createCampaign ( uint _minimum ) public {
        Campaign newCampaign = new Campaign(_minimum, msg.sender); // create new campaign contract
        deployedCampaigns.push(address(newCampaign)); 
    }

    function getDeployedCampaigns() public view returns ( address[] memory){
        return deployedCampaigns;
    }

}

contract Campaign{

     struct Request{
        string description;
        uint value;
        address payable recipient;
        bool complete;
        uint approvalCount; //no of yes votes this request has
        mapping (address => bool) approvedRequest; // tracking whether or not an address has voted on a given request
    }

    address public manager;
    uint public minimumContribution;
    // address[] public approvers; // this wrong approach, bcus iterating through the array will cost alot of gas
    mapping(address => bool) public approvers;
    uint public approversCount; //incremented everytim someone donates to our campaign

    // ==> array is used in 0.4.17
    // Request[] public requests;

    // =======> for version 0.8 code
    uint numRequests; //to track the index sort of
    mapping(uint => Request) requests; //


    modifier restricted () {
        require (msg.sender == manager);
        _;
    }

    constructor ( uint minimum, address creator ) {
        manager = creator;
        minimumContribution = minimum;
    }

    // function to enable making a contribution
    function contribute() public payable{
        require( msg.value > minimumContribution );
        approvers[msg.sender] = true;
        approversCount++;
    }

    // function to enable admin make a request for funding
    function createRequest( string memory _description, uint _value, address payable _recipient ) public  restricted {
        // Request memory newRequest = Request ({
        //     description: _description,
        //     value: _value,
        //     recipient:_recipient,
        //     complete: false,
        //     approvalCount: 0
        // });

        // ===>>>>version 0.8 code
            Request storage newRequest = requests[numRequests++];
        newRequest.description = _description;
        newRequest.value = _value;
        newRequest.recipient = _recipient;
        newRequest.complete = false;
        newRequest.approvalCount = 0;
        //  ===>>> ends here

    
        // requests.push(newRequest);
    }

    function approveRequest (uint _index) public {
        Request storage request = requests[_index];


        require(approvers[msg.sender]); // user must have donated to campaign
        require (!request.approvedRequest[msg.sender]); //check if address has not voted on this request

        request.approvedRequest[msg.sender] = true;
        request.approvalCount++;
    }

    function finalizeRequest( uint _index ) public restricted{
        Request storage request = requests[_index];

        require(request.approvalCount > (approversCount/2));
        require(!request.complete); // check its not a completed request

        request.recipient.transfer(request.value);
        request.complete = true;
    }
}