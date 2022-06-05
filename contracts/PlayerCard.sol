//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./ERC1155Tradeable.sol";

contract PlayerCard is ERC1155Tradeable {
    constructor (address _proxyRegistryAddress) ERC1155Tradeable(
        "Test Token",
        "TST",
        "http://localhost:8000/api/tokens/{id}",
        _proxyRegistryAddress
    ) {}
}