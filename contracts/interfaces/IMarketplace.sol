// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

interface IMarketplace {

    struct MarketplaceListing {
        address poolAddress;
        address seller;
        bool exists;
        uint tokenClass;
        uint numberOfTokens;
        uint price;
    }

    /**
    * @dev Given the address of a user and a pool address, returns the index of the marketplace listing
    * @notice Returns 0 if user doesn't have a listing in the given pool
    * @param user Address of the user
    * @param poolAddress Address of the pool's token
    * @return uint Index of the user's marketplace listing
    */
    function getListingIndex(address user, address poolAddress) external view returns (uint);

    /**
    * @dev Given the index of a marketplace listing, returns the listing's data
    * @param index Index of the marketplace listing
    * @return (address, address, uint, uint, uint) Pool token for sale, address of the seller, pool token's class, number of tokens for sale, USD per token
    */
    function getMarketplaceListing(uint index) external view returns (address, address, uint, uint, uint);

    /**
    * @dev Purchases the specified number of tokens from the marketplace listing
    * @param poolAddress Address of the pool token for sale
    * @param index Index of the marketplace listing
    * @param numberOfTokens Number of tokens to purchase
    */
    function purchase(address poolAddress, uint index, uint numberOfTokens) external;

    /**
    * @dev Creates a new marketplace listing with the given price and quantity
    * @param poolAddress Address of the pool token for sale
    * @param tokenClass The class of the pool's token
    * @param numberOfTokens Number of tokens to sell
    * @param price USD per token
    */
    function createListing(address poolAddress, uint tokenClass, uint numberOfTokens, uint price) external;

    /**
    * @dev Removes the marketplace listing at the given index
    * @param poolAddress Address of the pool's token for sale
    * @param index Index of the marketplace listing
    */
    function removeListing(address poolAddress, uint index) external;

    /**
    * @dev Updates the price of the given marketplace listing
    * @param poolAddress Address of the pool's token for sale
    * @param index Index of the marketplace listing
    * @param newPrice USD per token
    */
    function updatePrice(address poolAddress, uint index, uint newPrice) external;

    /**
    * @dev Updates the number of tokens for sale of the given marketplace listing
    * @param poolAddress Address of the pool's token for sale
    * @param index Index of the marketplace listing
    * @param newQuantity Number of tokens to sell
    */
    function updateQuantity(address poolAddress, uint index, uint newQuantity) external;

    /* ========== EVENTS ========== */

    event CreatedListing(address indexed seller, address indexed poolAddress, uint marketplaceListing, uint tokenClass, uint numberOfTokens, uint price);
    event RemovedListing(address indexed seller, address indexed poolAddress, uint marketplaceListing);
    event UpdatedPrice(address indexed seller, address indexed poolAddress, uint marketplaceListing, uint newPrice);
    event UpdatedQuantity(address indexed seller, address indexed poolAddress, uint marketplaceListing, uint newQuantity);
    event Purchased(address indexed buyer, address indexed poolAddress, uint marketplaceListing, uint numberOfTokens, uint tokenPrice);
}