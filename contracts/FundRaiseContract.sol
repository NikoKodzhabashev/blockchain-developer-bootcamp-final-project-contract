// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


/// @title A POC for a fund raising contract
/// @author Niko Kodzhabahev
/// @notice You can use this contract for only the most basic functions as create, donate and withdraw funds.
/// @custom:experimental This is an experimental contract.
contract FundRaiseContract is Initializable, OwnableUpgradeable {
    // Tracks the number of created campaigns
    uint256 public campaignId;
    // Tracks the number of created users
    uint256 private userId;

    // Stores the statuses of the campaigns
    enum FundRaiseStatus {
        Active,
        Completed
    }

    // Structure of the fund raiser
    struct FundRaiser {
        address userAddress;
        uint256 id;
        uint256[] campaignIds;
        bool isRegistered;
    }

    // Stores the fund raisers
    mapping(address => FundRaiser) public fundRaisers;

    // Structure of the campaign
    // This timestamp is used to calculate whether the campaign is active or not
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

    // Stores the campaigns
    mapping(uint256 => Campaign) public campaigns;

    /// @notice Logs the creation of a new campaign
    /// @param owner the owner of the campaign
    /// @param campaignId the id of the campaign
    event FundRaiseCreate(address indexed owner, uint256 campaignId);

    /// @notice Logs the donation of a new campaign
    /// @param donator the address of the user who donated
    /// @param campaignId the id of the campaign
    /// @param amount the amount of tokens donated
    event FundRaiseDonate(
        address indexed donator,
        uint256 campaignId,
        uint256 amount
    );

    /// @notice Logs the withdrawal of a new campaign
    /// @param owner the address of the user who withdrew
    /// @param campaignId the id of the campaign
    /// @param amount the amount of tokens withdrawn
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

    /// @notice Creates a new campaign
    /// @param expireOf the expiration of the campaign
    /// @param goal the goal of the campaign
    /// @param title the title of the campaign
    /// @param description the description of the campaign
    /// @param ipfsHash the ipfs hash of the campaign
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

    /// @notice Donates to a campaign
    /// @param campaignId the id of the campaign
    function donate(uint256 _campaignId) public payable {
        require(
            block.timestamp < campaigns[_campaignId].expireOf,
            "You cant donate to finished campaigns."
        );
        
        campaigns[_campaignId].currentAmount += msg.value;
        emit FundRaiseDonate(msg.sender, _campaignId, msg.value);
    }

    /// @notice Withdraws funds from a campaign
    /// @param campaignId the id of the campaign
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

    /// @notice Returns all camapaigns of the user
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

    /// @notice Returns all campaigns
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
