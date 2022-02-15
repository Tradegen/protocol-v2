// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

//Openzeppelin
import "./openzeppelin-solidity/contracts/SafeMath.sol";
import "./openzeppelin-solidity/contracts/ERC20/SafeERC20.sol";
import "./openzeppelin-solidity/contracts/ERC1155/IERC1155.sol";
import "./openzeppelin-solidity/contracts/ERC1155/ERC1155Holder.sol";

//Inheritance
import './interfaces/IMarketplace.sol';

//Interfaces
import './interfaces/IAddressResolver.sol';
import './interfaces/ISettings.sol';
import './interfaces/IAssetHandler.sol';
import './interfaces/ICappedPool.sol';

contract Marketplace is IMarketplace, ERC1155Holder {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IAddressResolver public immutable ADDRESS_RESOLVER;

    mapping (uint => MarketplaceListing) public marketplaceListings; //starts at index 1; increases without bounds
    uint public numberOfMarketplaceListings;
    mapping (address => mapping (address => uint)) public userToListingIndex; //max 1 listing per user per pool

    //Address of the pool's manager (used for sending manager's fee)
    //Set to address(0) if invalid pool
    mapping (address => address) public poolManagers; 

    constructor(IAddressResolver addressResolver) {
        ADDRESS_RESOLVER = addressResolver;
    }

    /* ========== VIEWS ========== */

   /**
    * @dev Given the address of a user and a pool address, returns the index of the marketplace listing
    * @notice Returns 0 if user doesn't have a listing in the given pool
    * @param user Address of the user
    * @param poolAddress Address of the pool's token
    * @return uint Index of the user's marketplace listing
    */
    function getListingIndex(address user, address poolAddress) external view override returns (uint) {
        require(user != address(0), "Marketplace: invalid user address");
        require(poolAddress != address(0), "Marketplace: invalid pool address");

        return userToListingIndex[poolAddress][user];
    }

    /**
    * @dev Given the index of a marketplace listing, returns the listing's data
    * @param index Index of the marketplace listing
    * @return (address, address, uint, uint, uint) Pool token for sale, address of the seller, pool token's class, number of tokens for sale, USD per token
    */
    function getMarketplaceListing(uint index) external view override indexInRange(index) returns (address, address, uint, uint, uint) {
        MarketplaceListing memory listing = marketplaceListings[index];

        return (listing.poolAddress, listing.seller, listing.tokenClass, listing.numberOfTokens, listing.price);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

   /**
    * @dev Purchases the specified number of tokens from the marketplace listing
    * @param poolAddress Address of the pool token for sale
    * @param index Index of the marketplace listing
    * @param numberOfTokens Number of tokens to purchase
    */
    function purchase(address poolAddress, uint index, uint numberOfTokens) external override isValidPool(poolAddress) {
        require(marketplaceListings[index].exists, "Listing doesn't exist");
        require(numberOfTokens > 0 &&
                numberOfTokens <= marketplaceListings[index].numberOfTokens,
                "Quantity out of bounds");
        require(msg.sender != marketplaceListings[index].seller, "Cannot buy your own position");
        
        address settingsAddress = ADDRESS_RESOLVER.getContractAddress("Settings");
        uint protocolFee = ISettings(settingsAddress).getParameterValue("MarketplaceProtocolFee");
        uint managerFee = ISettings(settingsAddress).getParameterValue("MarketplaceAssetManagerFee");
        address stableCoinAddress = IAssetHandler(ADDRESS_RESOLVER.getContractAddress("AssetHandler")).getStableCoinAddress();

        uint amountOfUSD = marketplaceListings[index].price.mul(numberOfTokens);

        IERC20(stableCoinAddress).safeTransferFrom(msg.sender, address(this), amountOfUSD);
        
        //Transfer mcUSD to seller
        IERC20(stableCoinAddress).safeTransfer(marketplaceListings[index].seller, amountOfUSD.mul(10000 - protocolFee - managerFee).div(10000));

        //TODO: implement xTGEN contract and swap protocol fee for TGEN

        //Pay manager fee
        IERC20(stableCoinAddress).safeTransfer(ICappedPool(poolAddress).manager(), amountOfUSD.mul(managerFee).div(10000));

        //Transfer tokens to buyer
        IERC1155(poolAddress).setApprovalForAll(msg.sender, true);
        IERC1155(poolAddress).safeTransferFrom(address(this), msg.sender, marketplaceListings[index].tokenClass, numberOfTokens, "");

        //Update marketplace listing
        if (numberOfTokens == marketplaceListings[index].numberOfTokens)
        {
            _removeListing(marketplaceListings[index].seller, poolAddress, index);
        }
        else
        {
            marketplaceListings[index].numberOfTokens = marketplaceListings[index].numberOfTokens.sub(numberOfTokens);
        }

        emit Purchased(msg.sender, poolAddress, index, numberOfTokens, marketplaceListings[index].price);
    }

    /**
    * @dev Creates a new marketplace listing with the given price and quantity
    * @param poolAddress Address of the pool token for sale
    * @param tokenClass The class of the pool's token
    * @param numberOfTokens Number of tokens to sell
    * @param price USD per token
    */
    function createListing(address poolAddress, uint tokenClass, uint numberOfTokens, uint price) external override isValidPool(poolAddress) {
        require(userToListingIndex[poolAddress][msg.sender] == 0, "Already have a marketplace listing for this pool");
        require(price > 0, "Price must be greater than 0");
        require(tokenClass > 0 && tokenClass < 5, "Token class must be between 1 and 4");
        require(numberOfTokens > 0 && numberOfTokens <= IERC1155(poolAddress).balanceOf(msg.sender, tokenClass), "Quantity out of bounds");

        numberOfMarketplaceListings = numberOfMarketplaceListings.add(1);
        userToListingIndex[poolAddress][msg.sender] = numberOfMarketplaceListings;
        marketplaceListings[numberOfMarketplaceListings] = MarketplaceListing(poolAddress, msg.sender, true, tokenClass, numberOfTokens, price);

        //Transfer tokens to marketplace
        IERC1155(poolAddress).safeTransferFrom(msg.sender, address(this), tokenClass, numberOfTokens, "");

        emit CreatedListing(msg.sender, poolAddress, numberOfMarketplaceListings, tokenClass, numberOfTokens, price);
    }

    /**
    * @dev Removes the marketplace listing at the given index
    * @param poolAddress Address of the pool's token for sale
    * @param index Index of the marketplace listing
    */
    function removeListing(address poolAddress, uint index) external override isValidPool(poolAddress) indexInRange(index) onlySeller(poolAddress, index) {
        uint numberOfTokens = marketplaceListings[index].numberOfTokens;

        _removeListing(msg.sender, poolAddress, index);

        //Transfer tokens to seller
        IERC1155(poolAddress).setApprovalForAll(msg.sender, true);
        IERC1155(poolAddress).safeTransferFrom(address(this), msg.sender, marketplaceListings[index].tokenClass, numberOfTokens, "");

        emit RemovedListing(msg.sender, poolAddress, index);
    }

     /**
    * @dev Updates the price of the given marketplace listing
    * @param poolAddress Address of the pool's token for sale
    * @param index Index of the marketplace listing
    * @param newPrice USD per token
    */
    function updatePrice(address poolAddress, uint index, uint newPrice) external override isValidPool(poolAddress) indexInRange(index) onlySeller(poolAddress, index) {
        require(newPrice > 0, "New price must be greater than 0");

        marketplaceListings[index].price = newPrice;

        emit UpdatedPrice(msg.sender, poolAddress, index, newPrice);
    }

    /**
    * @dev Updates the number of tokens for sale of the given marketplace listing
    * @param poolAddress Address of the pool's token for sale
    * @param index Index of the marketplace listing
    * @param newQuantity Number of tokens to sell
    */
    function updateQuantity(address poolAddress, uint index, uint newQuantity) external override isValidPool(poolAddress) indexInRange(index) onlySeller(poolAddress, index) {
        require(newQuantity > 0 &&
                newQuantity <= IERC1155(poolAddress).balanceOf(msg.sender, marketplaceListings[index].tokenClass),
                "Quantity out of bounds");

        uint oldQuantity = marketplaceListings[index].numberOfTokens;

        marketplaceListings[index].numberOfTokens = newQuantity;

        if (newQuantity > oldQuantity) {
            //Transfer tokens to marketplace
            IERC1155(poolAddress).safeTransferFrom(msg.sender, address(this), marketplaceListings[index].tokenClass, newQuantity.sub(oldQuantity), "");
        }
        else if (oldQuantity < newQuantity) {
            //Transfer tokens to seller
            IERC1155(poolAddress).setApprovalForAll(msg.sender, true);
            IERC1155(poolAddress).safeTransferFrom(address(this), msg.sender, marketplaceListings[index].tokenClass, oldQuantity.sub(newQuantity), "");
        }

        emit UpdatedQuantity(msg.sender, poolAddress, index, newQuantity);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
    * @dev Sets the marketplace listing's 'exists' variable to false and resets quantity.
    * @param user Address of the seller.
    * @param poolAddress Address of the pool's token.
    * @param index Index of the marketplace listing.
    */
    function _removeListing(address user, address poolAddress, uint index) internal {
        marketplaceListings[index].exists = false;
        marketplaceListings[index].numberOfTokens = 0;

        userToListingIndex[poolAddress][user] = 0;
    }

    /* ========== MODIFIERS ========== */

    modifier indexInRange(uint index) {
        require(index > 0 &&
                index <= numberOfMarketplaceListings,
                "Marketplace: Index out of range");
        _;
    }

    modifier onlySeller(address poolAddress, uint index) {
        require(index == userToListingIndex[poolAddress][msg.sender],
                "Marketplace: Only the seller can call this function");
        _;
    }

    modifier isValidPool(address pool) {
        require(ADDRESS_RESOLVER.checkIfPoolAddressIsValid(pool), 
                "Marketplace: Invalid pool");
        _;
    }
}