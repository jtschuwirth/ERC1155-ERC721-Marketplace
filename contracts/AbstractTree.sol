// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract AbstractTree is ERC721 {
    //View Functions

    function treeDNA(uint treeId) public virtual view returns (uint);

    function treeLevel(uint treeId) public virtual view returns (uint);

    function treeExp(uint treeId) public virtual view returns (uint);

    function treeRoots(uint treeId) public virtual view returns (uint);

    function treeBranches(uint treeId) public virtual view returns (uint);

    function actionStatus(uint treeId) public virtual view returns (uint);

    function currentAction(uint treeId) public virtual view returns (uint);

    function currentPrice() public virtual view returns (uint);

    function treesQuantity() public virtual view returns (uint);

    //Payable Functions

    function levelUpRoots(uint treeId, address user) public virtual;

    function levelUpBranches(uint treeId, address user) public virtual;

    function updateAction(uint treeId, uint action, uint value) public virtual;

    function gainExp(uint treeId, uint amount) public virtual;

    function gainLevel(uint treeId, address user) public virtual;

    function createNewTree() public virtual;
}