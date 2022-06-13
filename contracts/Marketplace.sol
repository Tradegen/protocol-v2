// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

// Openzeppelin.
import "./openzeppelin-solidity/contracts/SafeMath.sol";
import "./openzeppelin-solidity/contracts/ERC20/SafeERC20.sol";
import "./openzeppelin-solidity/contracts/ERC1155/IERC1155.sol";
import "./openzeppelin-solidity/contracts/ERC1155/ERC1155Holder.sol";

// Inheritance.
import './interfaces/IMarketplace.sol';

// Interfaces.
import './interfaces/IAddressResolver.sol';
import './interfaces/ISettings.sol';
import './interfaces/IAssetHandler.sol';
import './interfaces/ICappedPool.sol';
import './interfaces/IRouter.sol';

contract Marketplace is IMarketplace, ERC1155Holder {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IAddressResolver public immutable ADDRESS_RESOLVER;

    // (listing index => listing info).
    // Index starts at 1 and increases without bounds.
    mapping (uint256 => MarketplaceListing) public marketplaceListings;

    // Keep track of the cumulative number of marketplace listings.
    // This ensures that listing indexes are always unique.
    uint256 public numberOfMarketplaceListings;

    // (user => pool address => listing index).
    // User is limited to 1 listing per pool.
    mapping (address => mapping (address => uint256)) public userToListingIndex;

    constructor(address _addressResolver) {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Returns the index of the user's marketplace listing for the given pool.
    * @dev Returns 0 if the user doesn't have a listing for the given pool.
    * @param _user Address of the user.
    * @param _poolAddress Address of the pool.
    * @return uint256 Index of the user's marketplace listing.
    */
    function getListingIndex(address _user, address _poolAddress) external view override returns (uint256) {
        return userToListingIndex[_user][_poolAddress];
    }

    /**
    * @notice Given the index of a marketplace listing, returns the listing's data.
    * @param _index Index of the marketplace listing.
    * @return (bool, address, address, uint256, uint256, uint256) Whether the listing exists, address of the pool token, address of the seller, pool token's class, number of tokens for sale, USD per token.
    */
    function getMarketplaceListing(uint256 _index) external view override returns (bool, address, address, uint256, uint256, uint256) {
        MarketplaceListing memory listing = marketplaceListings[_index];

        return (listing.exists, listing.poolAddress, listing.seller, listing.tokenClass, listing.numberOfTokens, listing.price);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Purchases the given number of tokens from the marketplace listing.
    * @param _poolAddress Address of the pool.
    * @param _index Index of the marketplace listing.
    * @param _numberOfTokens Number of tokens to purchase.
    */
    function purchase(address _poolAddress, uint256 _index, uint256 _numberOfTokens) external override isValidPool(_poolAddress) {
        // Gas savings.
        MarketplaceListing memory listing = marketplaceListings[_index];

        require(listing.exists, "Marketplace: Listing doesn't exist.");
        require(_numberOfTokens > 0 &&
                _numberOfTokens <= listing.numberOfTokens,
                "Marketplace: Quantity out of bounds.");
        require(msg.sender != listing.seller, "Marketplace: Cannot buy your own position.");
        
        address settingsAddress = ADDRESS_RESOLVER.getContractAddress("Settings");
        uint256 protocolFee = ISettings(settingsAddress).getParameterValue("MarketplaceProtocolFee");
        uint256 managerFee = ISettings(settingsAddress).getParameterValue("MarketplaceAssetManagerFee");
        address stableCoinAddress = IAssetHandler(ADDRESS_RESOLVER.getContractAddress("AssetHandler")).getStableCoinAddress();

        uint256 amountOfUSD = listing.price.mul(_numberOfTokens);

        IERC20(stableCoinAddress).safeTransferFrom(msg.sender, address(this), amountOfUSD);
        
        // Transfer stablecoin to seller.
        IERC20(stableCoinAddress).safeTransfer(listing.seller, amountOfUSD.mul(10000 - protocolFee - managerFee).div(10000));
        
        {
        // Swap protocol fee for TGEN and send to xTGEN contract.
        address TGEN = ADDRESS_RESOLVER.getContractAddress("TGEN");
        uint256 initialTGEN = IERC20(TGEN).balanceOf(address(this));
        IRouter(ADDRESS_RESOLVER.getContractAddress("Router")).swapAssetForTGEN(stableCoinAddress, amountOfUSD.mul(protocolFee).div(10000));
        IERC20(TGEN).safeTransfer(ADDRESS_RESOLVER.getContractAddress("xTGEN"), IERC20(TGEN).balanceOf(address(this)).sub(initialTGEN));
        }

        // Pay manager fee.
        IERC20(stableCoinAddress).safeTransfer(ICappedPool(_poolAddress).manager(), amountOfUSD.mul(managerFee).div(10000));

        // Transfer tokens to buyer.
        IERC1155(ICappedPool(_poolAddress).getNFTAddress()).setApprovalForAll(msg.sender, true);
        IERC1155(ICappedPool(_poolAddress).getNFTAddress()).safeTransferFrom(address(this), msg.sender, listing.tokenClass, _numberOfTokens, "");

        // Update marketplace listing.
        if (_numberOfTokens == listing.numberOfTokens) {
            _removeListing(listing.seller, _poolAddress, _index);
        }
        else {
            marketplaceListings[_index].numberOfTokens = listing.numberOfTokens.sub(_numberOfTokens);
        }

        emit Purchased(msg.sender, _poolAddress, _index, _numberOfTokens, listing.price);
    }

    /**
    * @notice Creates a new marketplace listing with the given price and quantity.
    * @param _poolAddress Address of the pool.
    * @param _tokenClass The class of the pool's token.
    * @param _numberOfTokens Number of tokens to sell.
    * @param _price USD per token.
    */
    function createListing(address _poolAddress, uint256 _tokenClass, uint256 _numberOfTokens, uint256 _price) external override isValidPool(_poolAddress) {
        require(userToListingIndex[msg.sender][_poolAddress] == 0, "Marketplace: Already have a marketplace listing for this pool.");
        require(_price > 0, "Marketplace: Price must be greater than 0.");
        require(_tokenClass >= 1 && _tokenClass <= 4, "Marketplace: Token class must be between 1 and 4.");
        require(_numberOfTokens > 0 && _numberOfTokens <= IERC1155(ICappedPool(_poolAddress).getNFTAddress()).balanceOf(msg.sender, _tokenClass), "Marketplace: Quantity out of bounds.");

        numberOfMarketplaceListings = numberOfMarketplaceListings.add(1);
        userToListingIndex[msg.sender][_poolAddress] = numberOfMarketplaceListings;
        marketplaceListings[numberOfMarketplaceListings] = MarketplaceListing(_poolAddress, msg.sender, true, _tokenClass, _numberOfTokens, _price);

        // Transfer tokens to marketplace.
        IERC1155(ICappedPool(_poolAddress).getNFTAddress()).safeTransferFrom(msg.sender, address(this), _tokenClass, _numberOfTokens, "");

        emit CreatedListing(msg.sender, _poolAddress, numberOfMarketplaceListings, _tokenClass, _numberOfTokens, _price);
    }

    /**
    * @notice Removes the marketplace listing at the given index.
    * @param _poolAddress Address of the pool's token for sale.
    * @param _index Index of the marketplace listing.
    */
    function removeListing(address _poolAddress, uint256 _index) external override isValidPool(_poolAddress) indexInRange(_index) onlySeller(_poolAddress, _index) {
        uint256 numberOfTokens = marketplaceListings[_index].numberOfTokens;

        _removeListing(msg.sender, _poolAddress, _index);

        // Transfer tokens to seller.
        IERC1155(ICappedPool(_poolAddress).getNFTAddress()).setApprovalForAll(msg.sender, true);
        IERC1155(ICappedPool(_poolAddress).getNFTAddress()).safeTransferFrom(address(this), msg.sender, marketplaceListings[_index].tokenClass, numberOfTokens, "");

        emit RemovedListing(msg.sender, _poolAddress, _index);
    }

    /**
    * @notice Updates the price of the given marketplace listing.
    * @param _poolAddress Address of the pool's token for sale.
    * @param _index Index of the marketplace listing.
    * @param _newPrice USD per token.
    */
    function updatePrice(address _poolAddress, uint256 _index, uint256 _newPrice) external override isValidPool(_poolAddress) indexInRange(_index) onlySeller(_poolAddress, _index) {
        require(_newPrice > 0, "Marketplace: New price must be greater than 0.");

        marketplaceListings[_index].price = _newPrice;

        emit UpdatedPrice(msg.sender, _poolAddress, _index, _newPrice);
    }

    /**
    * @notice Updates the number of tokens for sale of the given marketplace listing.
    * @param _poolAddress Address of the pool's token for sale.
    * @param _index Index of the marketplace listing.
    * @param _newQuantity Number of tokens to sell.
    */
    function updateQuantity(address _poolAddress, uint256 _index, uint256 _newQuantity) external override isValidPool(_poolAddress) indexInRange(_index) onlySeller(_poolAddress, _index) {
        require(_newQuantity > 0 &&
                _newQuantity <= IERC1155(ICappedPool(_poolAddress).getNFTAddress()).balanceOf(msg.sender, marketplaceListings[_index].tokenClass),
                "Marketplace: Quantity out of bounds.");

        uint256 oldQuantity = marketplaceListings[_index].numberOfTokens;

        marketplaceListings[_index].numberOfTokens = _newQuantity;

        if (_newQuantity > oldQuantity) {
            // Transfer tokens to marketplace.
            IERC1155(ICappedPool(_poolAddress).getNFTAddress()).safeTransferFrom(msg.sender, address(this), marketplaceListings[_index].tokenClass, _newQuantity.sub(oldQuantity), "");
        }
        else {
            //Transfer tokens to seller.
            IERC1155(ICappedPool(_poolAddress).getNFTAddress()).setApprovalForAll(msg.sender, true);
            IERC1155(ICappedPool(_poolAddress).getNFTAddress()).safeTransferFrom(address(this), msg.sender, marketplaceListings[_index].tokenClass, oldQuantity.sub(_newQuantity), "");
        }

        emit UpdatedQuantity(msg.sender, _poolAddress, _index, _newQuantity);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
    * @notice Sets the marketplace listing's 'exists' variable to false and resets quantity.
    * @param _user Address of the seller.
    * @param _poolAddress Address of the pool's token.
    * @param _index Index of the marketplace listing.
    */
    function _removeListing(address _user, address _poolAddress, uint256 _index) internal {
        marketplaceListings[_index].exists = false;
        marketplaceListings[_index].numberOfTokens = 0;

        userToListingIndex[_user][_poolAddress] = 0;
    }

    /* ========== MODIFIERS ========== */

    modifier indexInRange(uint256 _index) {
        require(_index > 0 &&
                _index <= numberOfMarketplaceListings,
                "Marketplace: Index out of range.");
        _;
    }

    modifier onlySeller(address _poolAddress, uint256 _index) {
        require(_index == userToListingIndex[msg.sender][_poolAddress],
                "Marketplace: Only the seller can call this function.");
        _;
    }

    modifier isValidPool(address _pool) {
        require(ADDRESS_RESOLVER.checkIfPoolAddressIsValid(_pool), 
                "Marketplace: Invalid pool.");
        _;
    }

    /* ========== EVENTS ========== */

    event CreatedListing(address seller, address poolAddress, uint256 marketplaceListing, uint256 tokenClass, uint256 numberOfTokens, uint256 price);
    event RemovedListing(address seller, address poolAddress, uint256 marketplaceListing);
    event UpdatedPrice(address seller, address poolAddress, uint256 marketplaceListing, uint256 newPrice);
    event UpdatedQuantity(address seller, address poolAddress, uint256 marketplaceListing, uint256 newQuantity);
    event Purchased(address buyer, address poolAddress, uint256 marketplaceListing, uint256 numberOfTokens, uint256 tokenPrice);
}