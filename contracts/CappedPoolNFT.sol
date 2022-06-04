// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// Openzeppelin.
import './openzeppelin-solidity/contracts/SafeMath.sol';
import "./openzeppelin-solidity/contracts/ERC1155/ERC1155.sol";

// Interfaces.
import './interfaces/ICappedPool.sol';

// Inheritance.
import './interfaces/ICappedPoolNFT.sol';

contract CappedPoolNFT is ICappedPoolNFT, ERC1155 {
    using SafeMath for uint256;

    address public immutable pool;
    uint256 public immutable supplyCap;

    uint256[4] public availableTokensByClass;

    // User pool tokens.
    mapping (address => uint256) public override balance;
    uint256 public override totalSupply;

    // Keep track of cost basis to calculate unrealized profits.
    // Unrealized profits are used to update pool weights in the farming system.
    // (user address => user's cost basis).
    mapping (address => uint256) public override userDeposits;
    uint256 public override totalDeposits;

    constructor(address _pool, uint256 _supplyCap) {
        pool = _pool;
        supplyCap = _supplyCap;

        availableTokensByClass[0] = (_supplyCap.mul(5).div(100) > 1) ? _supplyCap.mul(5).div(100) : 1;
        availableTokensByClass[1] = (_supplyCap.mul(10).div(100) > 2) ? _supplyCap.mul(10).div(100) : 2;
        availableTokensByClass[2] = (_supplyCap.mul(20).div(100) > 3) ? _supplyCap.mul(20).div(100) : 3;
        availableTokensByClass[3] = _supplyCap.sub(availableTokensByClass[2]).sub(availableTokensByClass[1]).sub(availableTokensByClass[0]);
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Returns the number of tokens available for each class.
    * @return (uint256, uint256, uint256, uint256) Number of available C1, C2, C3, and C4 tokens.
    */
    function getAvailableTokensPerClass() external view override returns (uint256, uint256, uint256, uint256) {
        return (availableTokensByClass[0], availableTokensByClass[1], availableTokensByClass[2], availableTokensByClass[3]);
    }

    /**
    * @notice Returns the number of tokens the given user has for each class.
    * @param _user Address of the user.
    * @return (uint256, uint256, uint256, uint256) Number of available C1, C2, C3, and C4 tokens.
    */
    function getTokenBalancePerClass(address _user) external view override returns (uint256, uint256, uint256, uint256) {
        return (balanceOf(_user, 1), balanceOf(_user, 2), balanceOf(_user, 3), balanceOf(_user, 4));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Distributes user's deposit into different token classes based on how many tokens are available for each class.
    * @dev Attempt to distribute C1 first and work up to C4.
    * @dev This function can only be called by the CappedPool contract.
    * @param _user Address of the user.
    * @param _numberOfTokens Total number of tokens to distribute to the user.
    * @param _amountOfUSD Amount of USD to add to the cost basis.
    * @return uint256 The total cost basis of the pool.
    */
    function depositByClass(address _user, uint256 _numberOfTokens, uint256 _amountOfUSD) external override onlyPool returns (uint256) {
        uint256 amount;

        balance[_user] = balance[_user].add(_numberOfTokens);
        totalSupply = totalSupply.add(_numberOfTokens);

        // Update the cost basis.
        userDeposits[_user] = userDeposits[_user].add(_amountOfUSD);
        totalDeposits = totalDeposits.add(_amountOfUSD);

        {
        uint256 availableC1 = availableTokensByClass[0];
        if (availableC1 > 0 && _numberOfTokens > 0)
        {
            amount = (_numberOfTokens > availableC1) ? availableC1 : _numberOfTokens;
            _mint(_user, 1, amount, "");
            availableTokensByClass[0] = availableC1.sub(amount);
            _numberOfTokens = _numberOfTokens.sub(amount);
        }
        }

        {
        uint256 availableC2 = availableTokensByClass[1];
        if (availableC2 > 0 && _numberOfTokens > 0)
        {
            amount = (_numberOfTokens > availableC2) ? availableC2 : _numberOfTokens;
            _mint(_user, 2, amount, "");
            availableTokensByClass[1] = availableC2.sub(amount);
            _numberOfTokens = _numberOfTokens.sub(amount);
        }
        }

        {
        uint256 availableC3 = availableTokensByClass[2];
        if (availableC3 > 0 && _numberOfTokens > 0)
        {
            amount = (_numberOfTokens > availableC3) ? availableC3 : _numberOfTokens;
            _mint(_user, 3, amount, "");
            availableTokensByClass[2] = availableC3.sub(amount);
            _numberOfTokens = _numberOfTokens.sub(amount);
        }
        }

        {
        uint256 availableC4 = availableTokensByClass[3];
        if (availableC4 > 0 && _numberOfTokens > 0)
        {
            amount = (_numberOfTokens > availableC4) ? availableC4 : _numberOfTokens;
            _mint(_user, 4, amount, "");
            availableTokensByClass[3] = availableC4.sub(amount);
            _numberOfTokens = _numberOfTokens.sub(amount);
        }
        }

        return totalDeposits;
    }

    /**
    * @notice Burns the user's tokens for the given class.
    * @dev This function can only be called by the CappedPool contract.
    * @param _user Address of the user.
    * @param _tokenClass The class (C1 - C4) of the token.
    * @param _numberOfTokens Number of tokens to burn for the given class.
    * @return uint256 The total cost basis of the pool.
    */
    function burnTokens(address _user, uint256 _tokenClass, uint256 _numberOfTokens) external override onlyPool returns (uint256) {
        // Update the cost basis.
        totalDeposits = totalDeposits.sub(userDeposits[_user].mul(_numberOfTokens).div(balance[_user]));
        userDeposits[_user] = userDeposits[_user].sub(userDeposits[_user].mul(_numberOfTokens).div(balance[_user]));

        balance[_user] = balance[_user].sub(_numberOfTokens);
        totalSupply = totalSupply.sub(_numberOfTokens);
        availableTokensByClass[_tokenClass.sub(1)] = availableTokensByClass[_tokenClass.sub(1)].add(_numberOfTokens);

        _burn(_user, _tokenClass, _numberOfTokens);

        return totalDeposits;
    }

    /**
    * @notice Transfers tokens from seller to buyer.
    * @param from Address of the seller.
    * @param to Address of the buyer.
    * @param id The class of the asset's token; in range [1, 4].
    * @param amount Number of tokens to transfer for the given class.
    * @param data Bytes data.
    */
    function safeTransferFrom(address from, address to, uint id, uint amount, bytes memory data) public override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        uint256 tokenPrice = ICappedPool(pool).tokenPrice();
        uint256 amountOfUSD = amount.mul(tokenPrice);
        uint256 decrement = userDeposits[from].mul(amount).div(balance[from]);

        userDeposits[from] = userDeposits[from].sub(decrement);
        userDeposits[to] = userDeposits[to].add(amountOfUSD);
        totalDeposits = totalDeposits.add(amountOfUSD).sub(decrement);

        balance[from] = balance[from].sub(amount);
        balance[to] = balance[to].add(amount);

        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public override {}

    /* ========== MODIFIERS ========== */

    modifier onlyPool() {
        require(msg.sender == pool, "CappedPoolNFT: Only the CappedPool contract can call this function.");
        _;
    }
}