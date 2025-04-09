//SPDX-License-Identifer:MIT

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

/**
* @title DSCEngine
* @author 0xJund
* The system is designed to be as minimal as possible and have the tokens maintain a 1 token == $1 peg
* This stablecoin has the following properties: Exogenous Collateral, Dollar Pegged, Algo Stable
* Like DAI but with no governance, no fees and only ETH and WBTC backing
* @notice This contract is the core of the DSC system and handles all the logic
* @notice Loosely based on the MakerDAO DSS(DAI) system
*/

contract DSCEngine {

/*//////////////////////////////////////////////////////////////
                                 ERRORS
//////////////////////////////////////////////////////////////*/

    error DscEngine__NeedsMoreThanZero(); 

/*//////////////////////////////////////////////////////////////
                               MODIFIERS
//////////////////////////////////////////////////////////////*/

    modifier moreThanZero(uint256 amount) {
        if(amount == 0) {
            revert DscEngine__NeedsMoreThanZero();
        }
        _;
    }

/*//////////////////////////////////////////////////////////////
                               FUNCTIONS
//////////////////////////////////////////////////////////////*/
    constructor() {}


/*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
//////////////////////////////////////////////////////////////*/
    
    function depositCollateralAndMintDsc() external {}

    /*
    * @param tokenCollateralAddress The address of token to deposit as collateral 
    * @param amountCollateral The amount of collateral to deposit
    */

    function despositCollateral(address tokenCollateralAddress, uint256 amountCollateral) moreThanZero(amountCollateral) external {}
    
    function redeemCollateralForDsc() external {}
    
    function redeemCollateral() external {}

    function mintDsc() external {}

    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}
}
