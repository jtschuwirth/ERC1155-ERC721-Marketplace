// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract AbstractPTG {

    function mint(address _address, uint amount) public virtual;

    function balanceOf(address _address) public view virtual returns (uint);

    function totalSupply() public view virtual returns (uint);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool);
}