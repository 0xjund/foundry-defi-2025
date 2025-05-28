//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {DecentralisedStableCoin} from "src/DecentralisedStableCoin.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralisedStableCoin dsc;
    DSCEngine dsce;
    HelperConfig config;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;

    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth,,) = config.activeNetworkConfig();
        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                           CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DscEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    /*//////////////////////////////////////////////////////////////
                               PRICE TEST
    //////////////////////////////////////////////////////////////*/

    function testGetUsdValue() public view {
        uint256 ethAmount = 15e18;
        // 15e18 * 2000/ETH = 30 000e18;
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = dsce.getUsdValue(weth, ethAmount);
        assertEq(expectedUsd, actualUsd);
    }

    function testGetTokenAmountFromUsd() public view {
        uint256 usdAmount = 100 ether;
        uint256 expectedWeth = 0.05 ether;
        uint256 actualWeth = dsce.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(expectedWeth, actualWeth);
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT COLLATERAL TESTS
    //////////////////////////////////////////////////////////////*/

    function testRevertsIfCollateralZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        vm.expectRevert(DSCEngine.DscEngine__NeedsMoreThanZero.selector);
        dsce.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock ranToken = new ERC20Mock("RAN", "RAN", USER, AMOUNT_COLLATERAL);
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DscEngine__NotAllowedToken.selector);
        dsce.depositCollateral(address(ranToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(USER);
        uint256 expectedDepositAmount = dsce.getTokenAmountFromUsd(weth, collateralValueInUsd);
        assertEq(totalDscMinted, 0);
        assertEq(expectedDepositAmount, AMOUNT_COLLATERAL);
    }
    /*//////////////////////////////////////////////////////////////
                            REDEEM AND BURN
    //////////////////////////////////////////////////////////////*/

    function testRedeemCollateralForDscIsGreaterThanZero() public depositedCollateral {
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DscEngine__NeedsMoreThanZero.selector);
        dsce.redeemCollateralForDsc(weth, 0, 0);
        vm.stopPrank();
    }

    // function testBurnAmountForRedeemIsCorrect() public depositedCollateral {
    //    // Arrange
    //    // uint256 dscMintedBefore = dsce.getDscMinted(USER);
    //     // Act
    //     vm.startPrank(USER);
    //     dsce.redeemCollateral(weth, AMOUNT_COLLATERAL);
    //     vm.stopPrank();
    //     // Assert
    //     //uint256 dscMintedAfter = dsce.getDscMinted(USER);
    //     //assertEq(dscMintedAfter, 0);
    // }

    function testCannotRedeemMoreThanBurned() public depositedCollateral {}

    function testBurningDscReducesSupply() public depositedCollateral {}

    function testRedeemCollateralUpdatesUserBalances() public depositedCollateral {}

    function testRedeemRevertsIfHealthFactorIsBroken() public depositedCollateral {}

    /*//////////////////////////////////////////////////////////////
                          BURN AND LIQUIDATION
    //////////////////////////////////////////////////////////////*/

    function testMoreThanZeroLiquidationReverts() public {}

    function testRevertsIfHealthFactorIsOK() public {}

    function testRevertsIfHealthFactorHasntImproved() public {}

    /*//////////////////////////////////////////////////////////////
                          PRIVATE AND INTERNAL
    //////////////////////////////////////////////////////////////*/

    function testPrivateBurnDsc() public {}

    function testRedeemCollateralPrivate() public {}

    function testGetAccountInformaitonPrivate() public {}

    function testHealthFactorPrivate() public {}

    function testHealthFactorIsBrokenPrivate() public {}

    function testRevertIfHealthFactorIsBroken() public {}

    function testCalculateHealthFactor() public {}
}
