// SPDX-License-Identifier: GPL-3.int208
// Modified from original
// OpenZeppelin Contracts v4.3.2 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Counters.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC721/IERC721.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC721/IERC721Receiver.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Address.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Context.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Strings.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/introspection/ERC165.sol";

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC20/IERC20.sol";

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Counters.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/math/SafeMath.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/access/Ownable.sol";

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    function getPokemonFromToken(uint256 tokenId) public view virtual returns (uint256) {
        return tokenId;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, getPokemonFromToken(tokenId).toString(), ".json")) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

/**
 * @title PokemonCards contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract PokemonCards is ERC721, Ownable, VRFConsumerBase  {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    
    struct RangeChallenges {
        uint lowerBound;
        uint upperBound;
        uint awardedPokemon;
        bool active;
    }
    
    bytes32 internal keyHash;
    uint256 internal fee;
        
    Counters.Counter private _tokenIds;
    Counters.Counter private _challengeIds;
    
    uint256 public cardPrice = 100000000000000; //0.0001 ETH

    uint public maxCardsPurchase = 5;
    
    uint public constant MAX_CARDS = 898;

    bool public saleIsActive = false;
    
    string private baseURI;
    
    // requestId => tokenId
    mapping(bytes32 => uint) private randomNumberRequest;
    
    // tokenId => pokemon
    mapping(uint => uint) private tokenToPokemon;
    
    // address => pokemon => bool
    mapping(address => mapping(uint => bool)) private pokedex;
    
    // challengeId => Challenge
    mapping(uint => RangeChallenges) private rangeChallenges;
    
    // When token is minted
    event TokenMinted(address indexed newOwner, uint256 indexed newItemId);
    
    // When random Pokemon Card is assigned to token
    event CardMinted(address indexed newOwner, uint256 indexed newItemId);

    constructor() 
    ERC721("PokemonCards", "PKC")
    VRFConsumerBase(
        0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
        0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
    ) {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    }
    
    /*
    * Verify sale is active
    */
    modifier activeSale {
        require(saleIsActive, "Sale is not active");
        _;
    }
    
    /*
    * Verify challenge exists
    */
    modifier challengeExists(uint _challengeId) {
        require(rangeChallenges[_challengeId].lowerBound != 0, "Challenge does not exists");
        _;
    }
    
    /*
    * Verify challenge is active
    */
    modifier challengeActive(uint _challengeId) {
        require(rangeChallenges[_challengeId].active == true, "Challenge is not active");
        _;
    }
    
    /*
     * This will give correct random generated Pokemon ID to URI.
     * Require it is already generated by random async call.
     */
    function getPokemonFromToken(uint256 tokenId) public view virtual override returns (uint256) {
        require(tokenToPokemon[tokenId] != 0, "Pokemon is still being generated");
        return tokenToPokemon[tokenId];
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() private returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     * Here is set a new random pokemon to token owner
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 randomPokemon = (randomness % MAX_CARDS) + 1;
        uint tokenId = randomNumberRequest[requestId];
        tokenToPokemon[tokenId] = randomPokemon;
        
        // Add to pokedex
        pokedex[ownerOf(tokenId)][randomPokemon] = true;
        
        // Send event to identify mint and generate backend random card
        emit CardMinted(ownerOf(tokenId), tokenId);
        
        // Erase random number request from memory
        delete randomNumberRequest[requestId];
    }
    
    /** 
     * Create RangeChallenge
     */
    function createRangeChallenge(uint _lowerBound, uint _upperBound, uint _pokemon, bool _active) public onlyOwner returns (uint256) {
        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();
        rangeChallenges[newChallengeId] = RangeChallenges(_lowerBound, _upperBound, _pokemon, _active);
        return newChallengeId;
    }
    
    /** 
     * Flip active RangeChallenge
     */
    function flipActiveRangeChallenge(uint _challengeId) public onlyOwner challengeExists(_challengeId) returns (bool) {
        rangeChallenges[_challengeId].active = !rangeChallenges[_challengeId].active;
        return rangeChallenges[_challengeId].active;
    }
    
    /** 
     * Award RangeChallenge
     */
    function awardRangeChallenge(uint _challengeId) public challengeExists(_challengeId) challengeActive(_challengeId) returns (bool) {
        // Incremental tokenIds for every card
        for(uint i = rangeChallenges[_challengeId].lowerBound; i <= rangeChallenges[_challengeId].upperBound; i++) {
            if (pokedex[msg.sender][i] == false) {
                return false;
            }
        }
        
        // Custom Mint
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        emit TokenMinted(msg.sender, newItemId);
        tokenToPokemon[newItemId] = rangeChallenges[_challengeId].awardedPokemon;
        
        // Add to pokedex
        pokedex[msg.sender][tokenToPokemon[newItemId]] = true;
        
        return true;
    }

    /**
     * Save LINK balance at owner account
     */
    function withdrawLINK() public onlyOwner {
      require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Transfer failed");
    }
    
    /*
    * Negate value of sale
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    /*
    * Setup base URI
    */
    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }
    
    /**
     * @dev Base URI for computing {tokenURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    /*
    * Setup maxCardsPurchase
    */
    function setMaxCardsPurchase(uint _maxCardsPurchase) public onlyOwner {
        maxCardsPurchase = _maxCardsPurchase;
    }
    
    /*
    * Setup cardPrice
    */
    function setCardPrice(uint _cardPrice) public onlyOwner {
        cardPrice = _cardPrice;
    }

    /*
    * Mint cards
    */
    function mintCards(uint numberOfCards) public payable activeSale {
        require(numberOfCards <= maxCardsPurchase, "Exceeded limit cards purchase");
        require(cardPrice.mul(numberOfCards) <= msg.value, "Not enough ether for this purchase");
        
        // Incremental tokenIds for every card
        for(uint i = 0; i < numberOfCards; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
            randomNumberRequest[getRandomNumber()] = newItemId;
            emit TokenMinted(msg.sender, newItemId);
        }
    }
}