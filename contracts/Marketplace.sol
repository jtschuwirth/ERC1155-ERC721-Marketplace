// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;

import "./AbstractGameItems.sol";
import "./AbstractPTG.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Marketplace is Initializable, AccessControlUpgradeable, ERC1155Holder {

    address GameItemsAddress;
    address TokenAddress;
    address TreasuryAddress;

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
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Receiver, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function CreateOffers(uint itemId, uint itemQnt, uint price) public {
        require(gameItems.balanceOf(msg.sender, 0) >= itemQnt);
        gameItems.safeTransferFrom(msg.sender, address(this), itemId, itemQnt, "");
        for (uint256 i = 0; i < itemQnt; i++) {
            offers.push(Offer(msg.sender, itemId, price, "Open"));
        }
    }

    function CancelOffers(uint[] calldata offerIds) public {
        for (uint256 i = 0; i < offerIds.length; i++) {
            require(offers[offerIds[i]].owner == msg.sender);
            gameItems.safeTransferFrom(address(this), msg.sender, offers[offerIds[i]].itemId, 1, "");
        }
    }

    function AcceptOffers(uint[] calldata offerIds) public {
        uint[] memory costs;
        for (uint256 i = 0; i < offerIds.length; i++) {
            require(offers[offerIds[i]].owner != msg.sender);
            costs[i] = offers[offerIds[i]].price;
        }
        uint totalCost = getSum(costs);
        require(PTG.balanceOf(msg.sender)>= totalCost);
        for (uint256 i = 0; i < offerIds.length; i++) {
            require(PTG.balanceOf(msg.sender)>= offers[offerIds[i]].price);
            PTG.transferFrom(msg.sender, offers[offerIds[i]].owner, offers[offerIds[i]].price*96/100);
            PTG.transferFrom(msg.sender, TreasuryAddress, offers[offerIds[i]].price*4/100);
            gameItems.safeTransferFrom(address(this), msg.sender, offers[offerIds[i]].itemId, 1, "");
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

    function getSum(uint[] memory arr) public pure returns(uint) {
        uint sum = 0;
        for(uint i = 0; i < arr.length; i++)
            sum = sum + arr[i];
        return sum;
}

}