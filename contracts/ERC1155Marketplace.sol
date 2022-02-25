// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract ERC1155Marketplace is Initializable, AccessControlUpgradeable, ERC1155HolderUpgradeable, ReentrancyGuardUpgradeable {

    event OfferStatusChange(uint256 offerId, string status);

    struct Offer {
        address owner;
        address nft;
        uint nftId;
        uint originalAmount;
        uint currentAmount;
        uint price;
        string status;
    }

    mapping(uint256 => Offer) offers;
    mapping(address => uint256[]) addressToOffers;
    mapping(address => bool) addressToBool;

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private offerCounter;

    uint256 Fee;
    address PayoutAddress;
    IERC20Upgradeable token;

    constructor() initializer {}

    function initialize(address Payout, address TokenAddress, address BaseERC1155Address) initializer public {
        PayoutAddress = Payout;
        Fee = 4;
        token = IERC20Upgradeable(TokenAddress);
        addressToBool[BaseERC1155Address] = true;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155ReceiverUpgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function getOffer(uint256 offerId) external view returns (address, address, uint256, uint256, uint256, uint256, string memory) {
        Offer memory offer = offers[offerId];
        return (offer.owner, offer.nft, offer.nftId, offer.originalAmount, offer.currentAmount, offer.price, offer.status);
    }

    function getOffersOfAddress(address addr) external view returns (uint256[] memory) {
        return addressToOffers[addr];
    }

    function getOfferQuantities() external view returns (uint256) {
        return offerCounter.current();
    }

    function CreateOffer(uint nftId, address nftAddress, uint itemQnt, uint price) external nonReentrant() {
        require(addressToBool[nftAddress] == true);
        require(IERC1155Upgradeable(nftAddress).balanceOf(msg.sender, nftId) >= itemQnt);
        
        IERC1155Upgradeable(nftAddress).safeTransferFrom(msg.sender, address(this), nftId, itemQnt, "");
        
        uint current = offerCounter.current();
        offerCounter.increment();
        offers[current] = Offer(msg.sender, nftAddress, nftId, itemQnt, itemQnt, price, "Open");
        addressToOffers[msg.sender].push(current);
        emit OfferStatusChange(current, "Open");
    }

    function CancelOffer(uint offerId) external nonReentrant() {
        require(offers[offerId].owner == msg.sender);
        require(keccak256(abi.encodePacked(offers[offerId].status)) == keccak256(abi.encodePacked("Open")));
        offers[offerId].status = "Cancelled";
        IERC1155Upgradeable(offers[offerId].nft).safeTransferFrom(address(this), msg.sender, offers[offerId].nftId, offers[offerId].currentAmount, "");
        emit OfferStatusChange(offerId, offers[offerId].status);
    }

    function AcceptOffer(uint offerId, uint itemQnt) external nonReentrant() {
        require(offers[offerId].owner != msg.sender);
        require(keccak256(abi.encodePacked(offers[offerId].status)) == keccak256(abi.encodePacked("Open")));
        uint totalPrice = offers[offerId].price*itemQnt;
        require(token.balanceOf(msg.sender)>= totalPrice);
        require(itemQnt <= offers[offerId].currentAmount);

        offers[offerId].currentAmount = offers[offerId].currentAmount - itemQnt;
        if (offers[offerId].currentAmount == 0) {
            offers[offerId].status = "Closed";
        }
        token.safeTransferFrom(msg.sender, offers[offerId].owner, totalPrice*(100-Fee)/100);
        token.safeTransferFrom(msg.sender, PayoutAddress, totalPrice*Fee/100);
        IERC1155Upgradeable(offers[offerId].nft).safeTransferFrom(address(this), msg.sender, offers[offerId].nftId, itemQnt, "");
        emit OfferStatusChange(offerId, offers[offerId].status);

    }

    /**
     * @dev Changes account to send payout.
     * @param newPayout new address to send payout.
     */
    function transferPayoutAddress(address newPayout) external onlyRole(DEFAULT_ADMIN_ROLE) {
        PayoutAddress = newPayout;
    }

    /**
     * @dev Changes the fee 
     * @param newFee new fee.
     */
    function changeFee(uint256 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Fee = newFee;
    }

        /**
     * @dev adds new contract ERC1155 to the protocol
     * @param _contract contract address to whitelist.
     */
    function addContract(address _contract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        addressToBool[_contract] = true;
    }

    /**
     * @dev removes a contract ERC1155 from the protocol
     * @param _contract contract address to blacklist.
     */
    function removeContract(address _contract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        addressToBool[_contract] = false;
    }

}