// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

interface IMarketplace {

    struct MarketplaceListing {
        address poolAddress;
        address seller;
        bool exists;
        uint256 tokenClass;
        uint256 numberOfTokens;
        uint256 price;
    }

    /**
    * @notice Returns the index of the user's marketplace listing for the given pool.
    * @dev Returns 0 if the user doesn't have a listing for the given pool.
    * @param _user Address of the user.
    * @param _poolAddress Address of the pool.
    * @return uint256 Index of the user's marketplace listing.
    */
    function getListingIndex(address _user, address _poolAddress) external view returns (uint256);

    /**
    * @notice Given the index of a marketplace listing, returns the listing's data.
    * @param _index Index of the marketplace listing.
    * @return (address, address, uint256, uint256, uint256) Address of the pool token, address of the seller, pool token's class, number of tokens for sale, USD per token.
    */
    function getMarketplaceListing(uint256 _index) external view returns (address, address, uint256, uint256, uint256);

    /**
    * @notice Purchases the given number of tokens from the marketplace listing.
    * @param _poolAddress Address of the pool.
    * @param _index Index of the marketplace listing.
    * @param _numberOfTokens Number of tokens to purchase.
    */
    function purchase(address _poolAddress, uint256 _index, uint256 _numberOfTokens) external;

    /**
    * @notice Creates a new marketplace listing with the given price and quantity.
    * @param _poolAddress Address of the pool.
    * @param _tokenClass The class of the pool's token.
    * @param _numberOfTokens Number of tokens to sell.
    * @param _price USD per token.
    */
    function createListing(address _poolAddress, uint256 _tokenClass, uint256 _numberOfTokens, uint256 _price) external;

    /**
    * @notice Removes the marketplace listing at the given index.
    * @param _poolAddress Address of the pool's token for sale.
    * @param _index Index of the marketplace listing.
    */
    function removeListing(address _poolAddress, uint256 _index) external;

    /**
    * @notice Updates the price of the given marketplace listing.
    * @param _poolAddress Address of the pool's token for sale.
    * @param _index Index of the marketplace listing.
    * @param _newPrice USD per token.
    */
    function updatePrice(address _poolAddress, uint256 _index, uint256 _newPrice) external;

    /**
    * @notice Updates the number of tokens for sale of the given marketplace listing.
    * @param _poolAddress Address of the pool's token for sale.
    * @param _index Index of the marketplace listing.
    * @param _newQuantity Number of tokens to sell.
    */
    function updateQuantity(address _poolAddress, uint256 _index, uint256 _newQuantity) external;

    /* ========== EVENTS ========== */

    event CreatedListing(address seller, address poolAddress, uint256 marketplaceListing, uint256 tokenClass, uint256 numberOfTokens, uint256 price);
    event RemovedListing(address seller, address poolAddress, uint256 marketplaceListing);
    event UpdatedPrice(address seller, address poolAddress, uint256 marketplaceListing, uint256 newPrice);
    event UpdatedQuantity(address seller, address poolAddress, uint256 marketplaceListing, uint256 newQuantity);
    event Purchased(address buyer, address poolAddress, uint256 marketplaceListing, uint256 numberOfTokens, uint256 tokenPrice);
}