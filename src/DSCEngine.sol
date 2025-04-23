//SPDX-License-Identifier:MIT

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity 0.8.20;

import {DecentralisedStableCoin} from "src/DecentralisedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
* @title DSCEngine
* @author 0xJund
* The system is designed to be as minimal as possible and have the tokens maintain a 1 token == $1 peg
* This stablecoin has the following properties: Exogenous Collateral, Dollar Pegged, Algo Stable
* Like DAI but with no governance, no fees and only ETH and WBTC backing
* @notice This contract is the core of the DSC system and handles all the logic
* @notice Loosely based on the MakerDAO DSS(DAI) system
*/

contract DSCEngine is ReentrancyGuard {

/*//////////////////////////////////////////////////////////////
                                 ERRORS
//////////////////////////////////////////////////////////////*/

    error DscEngine__NeedsMoreThanZero(); 
    error DscEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error DscEngine__NotAllowedToken();
    error DscEngine__TransferFailed();
    error DscEngine__BreaksHealthFactor(uint256 healthFactor);
    error DscEngine__MintFailed();
    
/*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
//////////////////////////////////////////////////////////////*/
uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
uint256 private constant PRECISION = 1e18;
uint256 private constant LIQUIDATION_THRESHOLD = 50; //200% overcollateralized
uint256 private constant LIQUIDATION_PRECISION = 100;
uint256 private constant MIN_HEALTH_FACTOR = 1;

mapping(address token => address priceFeed) private s_priceFeeds;
mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited; 
mapping(address user => uint256 amountDscMinted) private s_DscMinted; 
address[] private s_collateralTokens;

DecentralisedStableCoin private immutable i_dsc;


/*//////////////////////////////////////////////////////////////
                                 EVENTS
//////////////////////////////////////////////////////////////*/

event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount); 

/*//////////////////////////////////////////////////////////////
                               MODIFIERS
//////////////////////////////////////////////////////////////*/

    modifier moreThanZero(uint256 amount) {
        if(amount == 0) {
            revert DscEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if(s_priceFeeds[token] == address(0)) {
            revert DscEngine__NotAllowedToken();
        }
        _;       
    }

/*//////////////////////////////////////////////////////////////
                               FUNCTIONS
//////////////////////////////////////////////////////////////*/

    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        if(tokenAddresses.length != priceFeedAddresses.length) {
            revert DscEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }
        for (uint256 i = 0; i< tokenAddresses.length; i++){
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        i_dsc = DecentralisedStableCoin(dscAddress);
    }


/*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
//////////////////////////////////////////////////////////////*/
    
    function depositCollateralAndMintDsc() external {}

    /*
    * @notice follows CEI pattern
    * @param tokenCollateralAddress The address of token to deposit as collateral 
    * @param amountCollateral The amount of collateral to deposit
    */

    function despositCollateral(address tokenCollateralAddress, uint256 amountCollateral) moreThanZero(amountCollateral) external moreThanZero(amountCollateral) isAllowedToken(tokenCollateralAddress) nonReentrant {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        // Remember to emit an event when you change state
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if(!success) {
            revert DscEngine__TransferFailed();
        }
    }
    
    function redeemCollateralForDsc() external {}
    
    function redeemCollateral() external {}

    /*
    * @notice follows CEI 
    * @param amountDscToMint The amount of DSC to mint
    * @notice they must have more collateral than the minimum threshold
    */
    function mintDsc(uint256 amountDscToMint) external moreThanZero(amountDscToMint) nonReentrant {
        s_DscMinted[msg.sender] += amountDscToMint;
        //revert if mint amount is above collateral limit
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountDscToMint);
        if(!minted){
            revert DscEngine__MintFailed();
        }
    }

    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}

/*//////////////////////////////////////////////////////////////
                  PRIVATE & INTERNAL VIEW FUNCTIONS
//////////////////////////////////////////////////////////////*/

    function _getAccountInformation(address user) private view returns(uint256 totalDscMinted, uint256 collateralValueInUsd) {
        totalDscMinted = s_DscMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    /*
    * Returns how close a liquidation a user is
    * If a user goes below 1, they can get liquidated
    */

    function _healthFactor(address user) private view returns(uint256) {
        // total DSC minited
        // total collateral VALUE
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;  
    }


    // Check Health Factor
    // Revert if requirements are not met
    
    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DscEngine__BreaksHealthFactor(userHealthFactor);
        } 
        }

/*//////////////////////////////////////////////////////////////
                     PUBLIC & EXTERNAL VIEW FUNCTIONS
//////////////////////////////////////////////////////////////*/

    function getAccountCollateralValue(address user) public view returns(uint256 totalCollateralValueInUsd) {
        // loop through each collateral token, get the amount and map it to the price to get the USD Value
        for(uint256 i = 0; i<s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;     
    }
    
    function getUsdValue(address token, uint256 amount) public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price ,,,) = priceFeed.latestRoundData();
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;  
    }   
}
