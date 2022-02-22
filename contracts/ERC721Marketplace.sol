// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract ERC721Marketplace is Initializable, AccessControlUpgradeable, ERC721HolderUpgradeable, ReentrancyGuardUpgradeable {

    event OfferStatusChange(uint256 offerId, string status);

    struct Offer {
        address owner;
        address nft;
        uint nftId;
        uint price;
        string status;
    }

    mapping(uint256 => Offer) offers;
    mapping(address => uint256[]) addressToOffers;
    mapping(address => bool) addressToBool;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private offerCounter;

    uint256 Fee;
    address PayoutAddress;
    IERC20Upgradeable token;

    function initialize(address Payout, address TokenAddress, address BaseERC721Address) initializer public {
        PayoutAddress = Payout;
        Fee = 4;
        token = IERC20Upgradeable(TokenAddress);
        addressToBool[BaseERC721Address] = true;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function getOffer(uint256 offerId) external view returns (address, address, uint256, uint256, string memory) {
        Offer memory offer = offers[offerId];
        return (offer.owner, offer.nft, offer.nftId, offer.price, offer.status);
    }

    function getOffersOfAddress(address addr) external view returns (uint256[] memory) {
        return addressToOffers[addr];
    }

    function getOfferQuantities() external view returns (uint256) {
        return offerCounter.current();
    }

    function CreateOffer(uint nftId, address nftAddress, uint price) external nonReentrant() {
        require(addressToBool[nftAddress] == true);
        require(IERC721Upgradeable(nftAddress).ownerOf(nftId) == msg.sender);
        
        IERC721Upgradeable(nftAddress).safeTransferFrom(msg.sender, address(this), nftId);
        offerCounter.increment();
        offers[offerCounter.current()] = Offer(msg.sender, nftAddress, nftId, price, "Open");
        addressToOffers[msg.sender].push(offerCounter.current());
        emit OfferStatusChange(offerCounter.current(), "Open");
    }

    function CancelOffer(uint offerId) external nonReentrant() {
        require(offers[offerId].owner == msg.sender);
        require(keccak256(abi.encodePacked(offers[offerId].status)) == keccak256(abi.encodePacked("Open")));
        offers[offerId].status = "Cancelled";
        IERC721Upgradeable(offers[offerId].nft).safeTransferFrom(address(this), msg.sender, offers[offerId].nftId);
        emit OfferStatusChange(offerId, offers[offerId].status);
    }

    function AcceptOffer(uint offerId) external nonReentrant() {
        require(offers[offerId].owner != msg.sender);
        require(keccak256(abi.encodePacked(offers[offerId].status)) == keccak256(abi.encodePacked("Open")));
        require(token.balanceOf(msg.sender)>= offers[offerId].price);
        
        token.transferFrom(msg.sender, offers[offerId].owner, offers[offerId].price*(100-Fee)/100);
        token.transferFrom(msg.sender, PayoutAddress, offers[offerId].price*(Fee)/100);
        IERC721Upgradeable(offers[offerId].nft).safeTransferFrom(address(this), msg.sender, offers[offerId].nftId);
        offers[offerId].status = "Closed";
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
     * @dev adds new contract ERC721 to the protocol
     * @param _contract contract address to whitelist.
     */
    function addContract(address _contract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        addressToBool[_contract] = true;
    }

    /**
     * @dev removes a contract ERC721 from the protocol
     * @param _contract contract address to blacklist.
     */
    function removeContract(address _contract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        addressToBool[_contract] = false;
    }
}