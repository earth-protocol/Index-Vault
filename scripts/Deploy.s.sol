// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/strategies/common/AbstractStrategy.sol";
import "../src/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "../src/strategies/staking/EarthIndex.sol";
import "../src/strategies/common/interfaces/IStrategy.sol";

contract Deploy is Script {
    
    address public router =0xdd9501781fa1c77584B0c55e0e68607AF3c35840;
    address public factory=0xE63D69fFdB211dD747ad8970544043fADE7d20f5;

    address public depositToken=0xBC3FCA55ABA295605830E25c7F5Ba9C58Ce0167C;
    address public tokenA=0xa38e9508368a823249b7eF291156F93CDcB8E66E;
    uint256 public tokenAallo=50;
    address public tokenB=0x98308Df644D91B78a797493C184dF7A731ecb530;
    uint256 public tokenBallo=30;
    address public tokenC=0xC23470d6A96BB96461789b032905e7CE8634d163;
    uint256 public tokenCallo=20;
    address public tokenD=0x989686C23206b121DcFA70C0042B8Fc29d7770a7;
    uint256 public tokenDallo=15;



    address protocol = 0x69605b7A74D967a3DA33A20c1b94031BC6cAF27c;
    address partner = 0x69605b7A74D967a3DA33A20c1b94031BC6cAF27c;
    uint256 partnerFee = 0;
    uint256 protocolFee = 0;
    uint256 fundManagerFee = 0;
    uint256 withdrawFee = 1;
    uint256 withdrawFeeDecimals = 100;
    uint256 feeDecimals = 100;



    
    uint256 stratUpdateDelay = 172800;
    uint256 vaultTvlCap = 10000e18;
     function setUp() public {}

     function run() public {
        uint privateKey = vm.envUint("PRIVATE_KEY");
        address acc = vm.addr(privateKey);
        console.log("Account", acc);

        vm.startBroadcast(privateKey);

          RiveraAutoCompoundingVaultV2Public vault = new RiveraAutoCompoundingVaultV2Public(
                depositToken,
                "Earth-USDC-Index-Vault",
                "Earth-USDC-Index-Vault",
                stratUpdateDelay,
                vaultTvlCap
            );
        CommonAddresses memory _commonAddresses = CommonAddresses(
            address(vault),
            router
        );


        EarthIndexParams memory _EarthParams =  EarthIndexParams(
            depositToken,
            factory,
            tokenA,
            tokenAallo,
            tokenB,
            tokenBallo,
            tokenC,
            tokenCallo
            // tokenD,
            // tokenDallo
        );


          EarthFeesParams memory feesParams = EarthFeesParams(
            protocol,
            partner,
            partnerFee,
            protocolFee,
            fundManagerFee,
            feeDecimals,
            withdrawFee,
            withdrawFeeDecimals
            );

            EarthIndex strat = new EarthIndex(
                _commonAddresses,
                feesParams,
                _EarthParams
            );

             vault.init(IStrategy(address(strat)));
            console.log("vault address is",address(vault));
            console.log("address is",address(strat));
     }
}
//  anvil --fork-url https://sepolia.blast.io --mnemonic "disorder pretty oblige witness close face food stumble name material couch planet"

// forge script scripts/Deploy.s.sol:Deploy --rpc-url http://127.0.0.1:8545/ --broadcast -vvv --legacy --slow
