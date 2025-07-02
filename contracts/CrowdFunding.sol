// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdFunding {
    string public name;
    string public  description;
    uint256 public goal;
    uint256 public deadline;
    address public owner;
    bool public paused;

    enum CampianState{Active, Successful, Failed}
    CampianState public state;
    struct Tier{
        string name;
        uint256 amount;
        uint256 backers;
    }

    struct Backer{
        uint256 totalContribution;
        mapping(uint256=> bool) fundedTiers;
    }

    Tier[] public tiers;
    mapping (address => Backer) public backers;
    modifier onlyOwner(){
        require (msg.sender == owner , "not the owner");
        _;

    }
    modifier campionOpen(){
        require(state == CampianState.Active , "campion is not active");
        _;
    }

    modifier notPaused(){
        require(!paused , "campion is paused");
        _;
    }

    constructor(
        address _owner,
        string memory _name,
        string memory _description,
        uint256 _goal,
        uint256 _durationinDays) {
            name = _name;
            description = _description;
            goal = _goal;
            deadline =  block.timestamp + (_durationinDays*1 days);
            owner = _owner;
            state=CampianState.Active;
        }
        function CheckandUpdateCampionState() internal {
            if (state== CampianState.Active){
                if (block.timestamp>= deadline){
                    state= address(this).balance >= goal?CampianState.Successful :CampianState.Failed ;
                }else {
                    state= address(this).balance >= goal?CampianState.Successful :CampianState.Active;
                }

            }

        }

        function fund( uint256 _tierIndex) public payable campionOpen notPaused{
            require(_tierIndex< tiers.length, "invalid tier");
            require(msg.value == tiers[_tierIndex].amount,"wrong amount");

            tiers[_tierIndex].backers++;
            backers[msg.sender].totalContribution += msg.value;
            backers[msg.sender].fundedTiers[_tierIndex]= true;
            CheckandUpdateCampionState();

        }
        function addTier(
            string memory _name,
            uint256 _amount
        ) public onlyOwner{
            require(_amount >0 , "amount must be greater then 0");
            tiers.push(Tier(_name,_amount,0));

        }
        function removeTier(uint256 _index) public onlyOwner{
            require(_index<tiers.length,"tier does not exist");
            tiers[_index] = tiers[tiers.length -1];
            tiers.pop();

            }

        function withdraw() public onlyOwner {
        CheckandUpdateCampionState();
        require(state == CampianState.Successful , "campion not successful");
         uint256 balance = address(this).balance;
        require(balance >0 , "no balance to withdraw");

        payable (owner).transfer(balance);
        }

        function getContractBalance() public view returns (uint256){
            return address(this).balance;

        }
        function refund() public{
            CheckandUpdateCampionState();
            require(state== CampianState.Failed, "Refund not availabe");
            uint256 amount = backers[msg.sender].totalContribution;
            require(amount > 0, "no contribution to refund");
            backers[msg.sender].totalContribution=0;
            payable (msg.sender).transfer(amount);

        }
        function hasFundedTier( address _backer,uint256 _tierIndex ) public view returns(bool){
            return backers[_backer].fundedTiers[_tierIndex];
            
        }
        function getTier() public view returns (Tier[] memory){
            return tiers;
        }
        function TogglePause() public onlyOwner{
            paused= !paused;
       }
       function getCampaignStatus() public view returns (CampianState){
        if(state == CampianState.Active && block.timestamp > deadline ){
            return  address(this).balance >= goal? CampianState.Successful :CampianState.Failed;
        }
        return state;

       }
       function extendDeadline(uint256 _daystoAdd) public onlyOwner campionOpen{
        deadline+= _daystoAdd*1 days ;
        
}
}