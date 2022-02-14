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
    event OfferClosed(uint offerId);

    address GameItemsAddress;
    address TokenAddress;
    address GameDevAddress;

    struct Offer {
        address owner;
        uint itemId;
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

    function CreateOffers(uint itemId, uint itemQnt, uint price) public {
        require(gameItems.balanceOf(msg.sender, 0) >= itemQnt);
        gameItems.safeTransferFrom(msg.sender, address(this), itemId, itemQnt, "");
        for (uint256 i = 0; i < itemQnt; i++) {
            uint id = offers.length;
            offers.push(Offer(msg.sender, itemId, price, "Open"));
            emit NewOffer(id);
        }
    }

    function CancelOffers(uint[] calldata offerIds) public {
        for (uint256 i = 0; i < offerIds.length; i++) {
            require(offers[offerIds[i]].owner == msg.sender);
            require(keccak256(abi.encodePacked(offers[offerIds[i]].status)) == keccak256(abi.encodePacked("Open")));
        }
        for (uint256 i = 0; i < offerIds.length; i++) {
            offers[offerIds[i]].status = "Cancelled";
            gameItems.safeTransferFrom(address(this), msg.sender, offers[offerIds[i]].itemId, 1, "");
            emit OfferCancelled(offerIds[i]);
        }
    }

    function AcceptOffers(uint[] calldata offerIds) public {
        uint[] memory costs;
        for (uint256 i = 0; i < offerIds.length; i++) {
            require(offers[offerIds[i]].owner != msg.sender);
            require(keccak256(abi.encodePacked(offers[offerIds[i]].status)) == keccak256(abi.encodePacked("Open")));
            costs[i] = offers[offerIds[i]].price;
        }
        uint totalCost = getSum(costs);
        require(PTG.balanceOf(msg.sender)>= totalCost);
        for (uint256 i = 0; i < offerIds.length; i++) {
            offers[offerIds[i]].status = "Closed";
            PTG.transferFrom(msg.sender, offers[offerIds[i]].owner, offers[offerIds[i]].price*96/100);
            PTG.transferFrom(msg.sender, GameDevAddress, offers[offerIds[i]].price*4/100);
            gameItems.safeTransferFrom(address(this), msg.sender, offers[offerIds[i]].itemId, 1, "");
            emit OfferClosed(offerIds[i]);
        }
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

    function getSum(uint[] memory arr) public pure returns(uint) {
        uint sum = 0;
        for(uint i = 0; i < arr.length; i++)
            sum = sum + arr[i];
        return sum;
}

}