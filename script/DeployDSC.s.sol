// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralisedStableCoin} from "src/DecentralisedStableCoin.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployDSC is Script {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses; 
    
    function run() external returns(DecentralisedStableCoin, DSCEngine, HelperConfig){
        HelperConfig config = new HelperConfig();

        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc, uint256 deployKey) = config.activeNetworkConfig();    

        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];
        
        vm.startBroadcast(deployKey);
        DecentralisedStableCoin dsc = new DecentralisedStableCoin();
        DSCEngine engine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));

        dsc.transferOwnership(address(engine)); 
        vm.stopBroadcast();
        return(dsc, engine, config);
    }
}
