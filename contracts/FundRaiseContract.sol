// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract FundRaiseContract {
    uint256 public campaignId = 0;
    uint256 private userId = 0;

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
    event FundRaiseDonateRejected(address indexed donator, string message);
    event FundRaiseWithdraw(
        address indexed owner,
        uint256 campaignId,
        uint256 amount
    );

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
            expireOf + block.timestamp,
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
        if (block.timestamp > campaigns[_campaignId].expireOf) {
            campaigns[_campaignId].expireOf = 0;
            campaigns[_campaignId].status = FundRaiseStatus.Completed;
            emit FundRaiseDonateRejected(
                msg.sender,
                "You cant donate to finished campaigns."
            );
        } else {
            campaigns[_campaignId].currentAmount += msg.value;
            emit FundRaiseDonate(msg.sender, _campaignId, msg.value);
        }
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

    function getAllCampaigns(uint256 _resultsPerPage, uint256 _page)
        external
        view
        returns (Campaign[] memory)
    {
        uint256 _returnCounter = 0;

        Campaign[] memory _campaigns = new Campaign[](_resultsPerPage);

        for (
            uint256 i = _resultsPerPage * _page - _resultsPerPage;
            i < _resultsPerPage * _page;
            i++
        ) {
            if (i < _campaigns.length - 1) {
                _campaigns[_returnCounter] = campaigns[_resultsPerPage + i];
            }
            _returnCounter++;
        }

        return _campaigns;
    }
}
