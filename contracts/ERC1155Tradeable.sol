//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract OwnableDelegateProxy { }

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract ERC1155Tradeable is ERC1155, Ownable {
    using Strings for string;
    using SafeMath for uint256;

    string public name;
    string public symbol;

    address proxyRegistryAddress;

    uint256 nonce;
    uint256 collectionNonce;

    mapping(uint256 => mapping(uint256 => uint256)) public collections; // collectionId => uint256 => [tokenIds]
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => string) customUri;

    constructor (
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _proxyRegistryAddress
    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    modifier ownersOnly(uint256 _id) {
        require(balanceOf(_msgSender(), _id) > 0, "Only owner allowed");
        _;
    }

    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    function uri(uint256 _id) override public view returns (string memory) {
        require(_exists(_id), "Token does not exist");
        
        bytes memory customUriBytes = bytes(customUri[_id]);

        if (customUriBytes.length > 0) {
            return customUri[_id];
        } else {
            return super.uri(_id);
        }
    }

    function create(string calldata _uri, uint256 _initialSupply) public onlyOwner returns (uint256 _id) {
        _id = ++nonce;

        if (bytes(_uri).length > 0) {
            customUri[_id] = _uri;
            emit URI(_uri, _id);
        }

        tokenSupply[_id] = _initialSupply;
        
        return _id;
    }

    function createCollection(uint256[] memory tokenIds) public onlyOwner returns (uint256 _id) {
        require(tokenIds.length > 0, "Must supply at least one token");
        
        _id = ++collectionNonce;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_exists(_id), "Token does not exist");
            require(totalSupply(_id) > 0, "Token must have non-zero supply");

            collections[_id][i] = tokenIds[i];
        }
    }

    function mint(address _to, uint256 _id, uint256 _quantity, bytes memory _data) virtual public {
        _mint(_to, _id, _quantity, _data);
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
    }

    /**
    * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
    */
    function isApprovedForAll(address _owner, address _operator) override public view returns (bool isOperator) {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);

        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    function _exists(uint256 _id) internal view returns (bool) {
        return nonce >= _id;
    }
    
    function exists(uint256 _id) external view returns (bool) {
        return _exists(_id);
    }
}
