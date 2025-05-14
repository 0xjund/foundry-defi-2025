// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralisedStableCoin} from "src/DecentralisedStableCoin.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {Handler} from "test/fuzz/Handler.t.sol";

contract InvariantsTest is StdInvariant, Test {
    DeployDSC deployer;
    DSCEngine dsce;
    DecentralisedStableCoin dsc;
    HelperConfig config;
    address weth;
    address wbtc;
    Handler handler;
    
    function setUp() external {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (,, weth, wbtc,) = config.activeNetworkConfig();
//      targetContract(address(dsce));
        handler = new Handler(dsce, dsc);
        targetContract(address (handler));   
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
        uint256 totalSupply = dsc.totalSupply();
        uint256 wethDeposited = IERC20(weth).balanceOf(address(dsce));
        uint256 wbtcDeposited = IERC20(wbtc).balanceOf(address(dsce));

        uint256 wethValue = dsce.getUsdValue(weth, wethDeposited);
        uint256 wbtcValue = dsce.getUsdValue(wbtc, wbtcDeposited);
         
        
        console.log("weth value:", wethValue);
        console.log("wbtc value:", wbtcValue);
        console.log("total supply:", totalSupply);
        console.log("Times mint called:", handler.timesMintIsCalled());
                
        assert(wethValue + wbtcValue >= totalSupply);
    }

    function invariant_gettersShouldNotRevert() public view {
        dsce.getAdditionalFeedPrecision();
        dsce.getCollateralTokens();
        dsce.getLiquidationBonus();
        dsce.getLiquidationThreshold();
        dsce.getMinHealthFactor();
        dsce.getPrecision();
        dsce.getDsc();
    }
    
}
