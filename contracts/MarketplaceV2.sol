// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;

import "./AbstractGameItems.sol";
import "./AbstractPTG.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Marketplace is Initializable, AccessControlUpgradeable, ERC1155Holder {

    event NewOffer(uint offerId);
    event OfferCancelled(uint offerId);
    event OfferUpdated(uint offerId);

    address GameItemsAddress;
    address TokenAddress;
    address GameDevAddress;

    struct Offer {
        address owner;
        uint itemId;
        uint originalAmount;
        uint currentAmount;
        uint price;
        string status;
    }

    Offer[] public offers;
    AbstractGameItems gameItems;
    AbstractPTG PTG;

    function initialize() initializer public {
        GameDevAddress = 0xfd768E668A158C173e9549d1632902C2A4363178;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Receiver, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    //View Functions
    function offerOwner(uint offerId) public view returns (address) {
        return offers[offerId].owner;
    }

    function offerItemId(uint offerId) public view returns (uint) {
        return offers[offerId].itemId;
    }

    function offerOriginalAmount(uint offerId) public view returns (uint) {
        return offers[offerId].originalAmount;
    }
    function offerCurrentAmount(uint offerId) public view returns (uint) {
        return offers[offerId].currentAmount;
    }

    function offerPrice(uint offerId) public view returns (uint) {
        return offers[offerId].price;
    }

    function offerStatus(uint offerId) public view returns (string memory) {
        return offers[offerId].status;
    }

    function offersQuantity() public view returns (uint) {
        uint quantity = offers.length;
        return quantity;
    }

    function CreateOffer(uint itemId, uint itemQnt, uint price) public {
        require(gameItems.balanceOf(msg.sender, itemId) >= itemQnt);
        gameItems.safeTransferFrom(msg.sender, address(this), itemId, itemQnt, "");
        offers.push(Offer(msg.sender, itemId, itemQnt, itemQnt, price, "Open"));
        uint id = offers.length;
        emit NewOffer(id);
    }

    function CancelOffer(uint offerId) public {
        require(offers[offerId].owner == msg.sender);
        require(keccak256(abi.encodePacked(offers[offerId].status)) == keccak256(abi.encodePacked("Open")));
        offers[offerId].status = "Cancelled";
        gameItems.safeTransferFrom(address(this), msg.sender, offers[offerId].itemId, offers[offerId].currentAmount, "");
        emit OfferCancelled(offerId);
    }

    function AcceptOffer(uint offerId, uint itemQnt) public {
        require(offers[offerId].owner != msg.sender);
        require(keccak256(abi.encodePacked(offers[offerId].status)) == keccak256(abi.encodePacked("Open")));
        uint totalPrice = offers[offerId].price*itemQnt;
        require(PTG.balanceOf(msg.sender)>= totalPrice);
        require(itemQnt <= offers[offerId].currentAmount);

        offers[offerId].currentAmount = offers[offerId].currentAmount - itemQnt;
        if (offers[offerId].currentAmount == 0) {
            offers[offerId].status = "Closed";
        }
        PTG.transferFrom(msg.sender, offers[offerId].owner, totalPrice*96/100);
        PTG.transferFrom(msg.sender, GameDevAddress, totalPrice*4/100);
        gameItems.safeTransferFrom(address(this), msg.sender, offers[offerId].itemId, itemQnt, "");
        emit OfferUpdated(offerId);

    }

    function transferGameItemsAddress(address newGameItems) public onlyRole(DEFAULT_ADMIN_ROLE) {
        GameItemsAddress = newGameItems;
        gameItems = AbstractGameItems(GameItemsAddress);
    }

    function transferTokenAddress(address newToken) public onlyRole(DEFAULT_ADMIN_ROLE) {
        TokenAddress = newToken;
        PTG = AbstractPTG(TokenAddress);
    }

    function transferGameDevAddress(address newGameDev) public onlyRole(DEFAULT_ADMIN_ROLE) {
        GameDevAddress = newGameDev;
    }

}