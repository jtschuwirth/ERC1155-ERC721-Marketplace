// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;

import "./AbstractPTG.sol";
import "./AbstractTree.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TreeMarketplace is Initializable, AccessControlUpgradeable, ERC721Holder {

    event OfferUpdated(uint offerId, address owner, uint treeId, uint price, string status);

    address TreeAddress;
    address TokenAddress;
    address GameDevAddress;

    struct Offer {
        address owner;
        uint treeId;
        uint price;
        string status;
    }

    Offer[] public offers;
    AbstractTree tree;
    AbstractPTG PTG;

    function initialize() initializer public {
        GameDevAddress = 0xfd768E668A158C173e9549d1632902C2A4363178;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

        //View Functions
    function offerOwner(uint offerId) public view returns (address) {
        return offers[offerId].owner;
    }

    function offerItemId(uint offerId) public view returns (uint) {
        return offers[offerId].treeId;
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

    function CreateOffer(uint treeId, uint price) public {
        require(tree.ownerOf(treeId) == msg.sender);
        tree.safeTransferFrom(msg.sender, address(this), treeId);
        uint offerId = offers.length;
        offers.push(Offer(msg.sender, treeId, price, "Open"));
        emit OfferUpdated(offerId, msg.sender, treeId, price, "Open");
    }

    function CancelOffer(uint offerId) public {
        require(offers[offerId].owner == msg.sender);
        require(keccak256(abi.encodePacked(offers[offerId].status)) == keccak256(abi.encodePacked("Open")));
        offers[offerId].status = "Cancelled";
        tree.safeTransferFrom(address(this), msg.sender, offers[offerId].treeId);
        emit OfferUpdated(offerId, offers[offerId].owner, offers[offerId].treeId, offers[offerId].price, offers[offerId].status);
    }

    function AcceptOffer(uint offerId) public {
        require(offers[offerId].owner != msg.sender);
        require(keccak256(abi.encodePacked(offers[offerId].status)) == keccak256(abi.encodePacked("Open")));
        require(PTG.balanceOf(msg.sender)>= offers[offerId].price);
        
        PTG.transferFrom(msg.sender, offers[offerId].owner, offers[offerId].price*96/100);
        PTG.transferFrom(msg.sender, GameDevAddress, offers[offerId].price*4/100);
        tree.safeTransferFrom(address(this), msg.sender, offers[offerId].treeId);
        offers[offerId].status = "Closed";
        emit OfferUpdated(offerId, offers[offerId].owner, offers[offerId].treeId, offers[offerId].price, offers[offerId].status);

    }

    function transferTreeAddress(address newTree) public onlyRole(DEFAULT_ADMIN_ROLE) {
        TreeAddress = newTree;
        tree = AbstractTree(TreeAddress);
    }

    function transferTokenAddress(address newToken) public onlyRole(DEFAULT_ADMIN_ROLE) {
        TokenAddress = newToken;
        PTG = AbstractPTG(TokenAddress);
    }

    function transferGameDevAddress(address newGameDev) public onlyRole(DEFAULT_ADMIN_ROLE) {
        GameDevAddress = newGameDev;
    }
}