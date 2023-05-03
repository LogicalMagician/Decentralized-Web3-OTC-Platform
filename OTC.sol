// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract OTCTrading {
    using SafeMath for uint256;
    using Address for address;

    struct Offer {
        address tokenAddress;
        uint256 tokenAmount;
        uint256 etherAmount;
        address payable seller;
        bool isActive;
    }

    Offer[] public offers;

    event OfferCreated(uint256 indexed offerId, address indexed tokenAddress, uint256 tokenAmount, uint256 etherAmount, address indexed seller);
    event OfferFulfilled(uint256 indexed offerId, address indexed buyer);

    function createOffer(address tokenAddress, uint256 tokenAmount, uint256 etherAmount) public {
        require(tokenAmount > 0, "Token amount must be greater than 0");
        require(etherAmount > 0, "Ether amount must be greater than 0");

        IERC20 token = IERC20(tokenAddress);
        require(token.allowance(msg.sender, address(this)) >= tokenAmount, "Token allowance too small");

        token.transferFrom(msg.sender, address(this), tokenAmount);

        Offer memory newOffer = Offer({
            tokenAddress: tokenAddress,
            tokenAmount: tokenAmount,
            etherAmount: etherAmount,
            seller: payable(msg.sender),
            isActive: true
        });

        offers.push(newOffer);
        uint256 offerId = offers.length - 1;

        emit OfferCreated(offerId, tokenAddress, tokenAmount, etherAmount, msg.sender);
    }

    function fulfillOffer(uint256 offerId) public payable {
        Offer storage offer = offers[offerId];
        require(offer.isActive, "Offer is not active");
        require(msg.value == offer.etherAmount, "Sent ether amount does not match the offer");

        IERC20 token = IERC20(offer.tokenAddress);
        token.transfer(msg.sender, offer.tokenAmount);
        offer.seller.transfer(offer.etherAmount);

        offer.isActive = false;

        emit OfferFulfilled(offerId, msg.sender);
    }

    function getOffersLength() public view returns (uint256) {
        return offers.length;
    }
}
