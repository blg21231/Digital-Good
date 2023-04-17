// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DigitalGood is ERC1155, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event NFTListed(
        uint256 tokenId,
        address lister,
        string name,
        string description,
        string category,
        uint256 listerPrice,
        uint256 totalSupply,
        string previewLink
    );
    event NFTBought(uint256 tokenId, address buyer, uint256 quantity);

    mapping(uint256 => address) public _listers;
    mapping(uint256 => string) private _accessLinks;

    // Adding Treasury wallet address variable
    address payable private _treasuryWallet;

    constructor(address payable treasuryWallet_) ERC1155("data:application/json,{}") {
        _treasuryWallet = treasuryWallet_;
    }

    function listNFT(
        string memory name,
        string memory description,
        string memory category,
        uint256 listerPrice,
        uint256 totalSupply,
        string memory previewLink,
        string memory accessLink
    ) public {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _listers[newItemId] = msg.sender;
        _accessLinks[newItemId] = accessLink;

        emit NFTListed(
            newItemId,
            msg.sender,
            name,
            description,
            category,
            listerPrice,
            totalSupply,
            previewLink
        );
    }

    function buyNFT(uint256 tokenId, uint256 listerPrice, uint256 quantity) public payable {
        if (quantity == 0) {
            quantity = 1;
        }
        uint256 requiredAmount = (listerPrice * 5 / 4) * quantity;
        require(msg.value >= requiredAmount, "Not enough funds to purchase NFT");

        address lister = _listers[tokenId];
        _mint(msg.sender, tokenId, quantity, "");

        uint256 listerPayout = listerPrice * quantity;
        uint256 remainingAmount = msg.value - listerPayout;
        payable(lister).transfer(listerPayout);

        // Transfer the remaining amount to the treasury wallet
        _treasuryWallet.transfer(remainingAmount);

        emit NFTBought(tokenId, msg.sender, quantity);
    }

    function getAccessLink(uint256 tokenId) public view returns (string memory) {
        require(balanceOf(msg.sender, tokenId) > 0, "Caller is not the owner of the NFT");
        return _accessLinks[tokenId];
    }

}
