// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


contract FundRaiseContract is Initializable, OwnableUpgradeable {
    uint256 public campaignId;
    uint256 private userId;

    enum FundRaiseStatus {
        Active,
        Completed
    }

    struct FundRaiser {
        address userAddress;
        uint256 id;
        uint256[] campaignIds;
        bool isRegistered;
    }
    mapping(address => FundRaiser) public fundRaisers;

    struct Campaign {
        uint256 id;
        uint256 goal;
        uint256 currentAmount;
        uint256 expireOf; // in seconds
        string description;
        string title;
        string ipfsHash;
        FundRaiseStatus status;
    }
    mapping(uint256 => Campaign) public campaigns;

    event FundRaiseCreate(address indexed owner, uint256 campaignId);
    event FundRaiseDonate(
        address indexed donator,
        uint256 campaignId,
        uint256 amount
    );
    event FundRaiseWithdraw(
        address indexed owner,
        uint256 campaignId,
        uint256 amount
    );

    function initialize() public virtual initializer {
        campaignId = 0;
        userId = 0;
        __Ownable_init();
    }

    function createCampaign(
        uint256 expireOf,
        uint256 goal,
        string memory title,
        string memory description,
        string memory ipfsHash
    ) public {
        Campaign memory _campaign = Campaign(
            campaignId,
            goal,
            0,
            expireOf,
            description,
            title,
            ipfsHash,
            FundRaiseStatus.Active
        );

        if (!fundRaisers[msg.sender].isRegistered) {
            fundRaisers[msg.sender].userAddress = msg.sender;
            fundRaisers[msg.sender].id = userId;
            fundRaisers[msg.sender].campaignIds.push(campaignId);
            fundRaisers[msg.sender].isRegistered = true;

            userId += 1;
        } else {
            fundRaisers[msg.sender].campaignIds.push(campaignId);
        }

        campaigns[campaignId] = _campaign;

        campaignId += 1;

        emit FundRaiseCreate(msg.sender, campaignId);
    }

    function donate(uint256 _campaignId) public payable {
        require(
            block.timestamp < campaigns[_campaignId].expireOf,
            "You cant donate to finished campaigns."
        );
        
        campaigns[_campaignId].currentAmount += msg.value;
        emit FundRaiseDonate(msg.sender, _campaignId, msg.value);
    }

    function withdraw(uint256 _campaignId) public payable {
        require(
            msg.sender == fundRaisers[msg.sender].userAddress,
            "Withdrawer not authorized."
        );

        require(
            block.timestamp > campaigns[_campaignId].expireOf,
            "Can't withdraw since the campaigns is still active."
        );

        uint256 accumulatedAmount = campaigns[_campaignId].currentAmount;

        payable(msg.sender).transfer(accumulatedAmount);

        campaigns[_campaignId].status = FundRaiseStatus.Completed;
        campaigns[_campaignId].expireOf = 0;
        campaigns[_campaignId].currentAmount = 0;

        emit FundRaiseWithdraw(msg.sender, _campaignId, accumulatedAmount);
    }

    function getAllCampaignsByAddress()
        external
        view
        returns (Campaign[] memory)
    {
        uint256[] memory campaignIds = fundRaisers[msg.sender].campaignIds;
        Campaign[] memory campaignsByAddress = new Campaign[](
            campaignIds.length
        );

        for (uint256 i = 0; i < campaignIds.length; i++) {
            campaignsByAddress[i] = campaigns[campaignIds[i]];
        }

        return campaignsByAddress;
    }

    function getAllCampaigns()
        external
        view
        returns (Campaign[] memory)
    {
        uint itemCount = campaignId;
        Campaign[] memory campaignList = new Campaign[](itemCount);
        
        for (uint i = 0; i < itemCount; i++) {
            Campaign memory currentCandidate = campaigns[i];
            campaignList[i] = currentCandidate;
        }

        return campaignList;
    }
}
