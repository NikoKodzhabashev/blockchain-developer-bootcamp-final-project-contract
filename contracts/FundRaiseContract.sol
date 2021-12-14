// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract FundRaiseContract {
    uint256 private campaignId = 0;
    uint256 private userId = 0;

    constructor() {}

    enum FundRaiseStatus {
        Active,
        Completed,
        Failed
    }

    struct FundRaiser {
        address userAddress;
        uint256[] campaignIds;
        uint256 id;
        bool isRegistered;
    }

    mapping(address => FundRaiser) fundRaisers;

    struct Campaign {
        uint256 goal;
        uint256 currentAmount;
        uint256 expireOf; // in seconds
        string description;
        string title;
        string ipfsHash;
        FundRaiseStatus status;
    }

    mapping(uint256 => Campaign) campaign;

    event FundRaiseCreate(address indexed owner, uint256 campaignId);
    event FundRaiseDonate(
        address indexed donator,
        uint256 campaignId,
        uint256 amount
    );
    event FundRaiseWithrdaw(
        address indexed owner,
        uint256 campaignId,
        uint256 amount
    );

    function createFundRaise(
        uint256 expireOf,
        uint256 goal,
        string memory title,
        string memory description,
        string memory ipfsHash
    ) public {
        Campaign memory _campaign = Campaign(
            goal,
            0,
            expireOf + block.timestamp,
            description,
            title,
            ipfsHash,
            FundRaiseStatus.Active
        );

        if (fundRaisers[msg.sender].isRegistered == false) {
            fundRaisers[msg.sender] = FundRaiser(
                msg.sender,
                new uint256[](campaignId),
                userId,
                true
            );
            userId += 1;
        } else {
            fundRaisers[msg.sender].campaignIds.push(campaignId);
        }

        campaign[campaignId] = _campaign;

        campaignId += 1;

        emit FundRaiseCreate(msg.sender, campaignId);
    }

    function donate(uint256 _campaignId) public payable {
        if (campaign[_campaignId].expireOf >= block.timestamp) {
            campaign[_campaignId].expireOf = 0;

            if (
                campaign[_campaignId].goal < campaign[_campaignId].currentAmount
            ) {
                campaign[_campaignId].status = FundRaiseStatus.Failed;
            } else {
                campaign[_campaignId].status = FundRaiseStatus.Completed;
            }

            revert("Fundraising finished.");
        }

        campaign[_campaignId].currentAmount += msg.value;

        emit FundRaiseDonate(msg.sender, _campaignId, msg.value);
    }

    function withdraw(uint256 _campaignId) public payable {
        require(
            msg.sender == fundRaisers[msg.sender].userAddress,
            "Withdrawer not authorized."
        );
        require(
            campaign[_campaignId].expireOf >= block.timestamp,
            "Can't withdraw since the campaign is still active."
        );

        uint256 accumulatedAmount = campaign[_campaignId].currentAmount;

        payable(msg.sender).transfer(accumulatedAmount);

        campaign[_campaignId].status = FundRaiseStatus.Completed;
        campaign[_campaignId].expireOf = 0;
        campaign[_campaignId].currentAmount = 0;

        emit FundRaiseWithrdaw(msg.sender, _campaignId, accumulatedAmount);
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
            campaignsByAddress[i] = campaign[campaignIds[i]];
        }

        return campaignsByAddress;
    }
}
