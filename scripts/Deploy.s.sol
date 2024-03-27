// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/strategies/common/AbstractStrategy.sol";
import "../src/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "../src/strategies/staking/EarthIndex.sol";
import "../src/strategies/common/interfaces/IStrategy.sol";

contract Deploy is Script {
    
    address public token = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address public user=0x171cda359aa49E46Dec45F375ad6c256fdFBD420;
    address public userWeth = 0xb835AF52422a14C917d4b37b36c9a73d24770261;

    address public userO = 0xFaBcc4b22fFEa25D01AC23c5d225D7B27CB1B6B8;


    address public router =0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;//arb univ3
    address public factory=0x1F98431c8aD98523631AE4a59f267346ea31F984; //arb univ3
    

    address public depositToken=0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;//arb usdc
    address public weth=0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; //arb weth
    address public tokenA=0x5979D7b546E38E414F7E9822514be443A4800529; //arb wstEth
    uint256 public tokenAallo=10;
    address public tokenB=0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;//arb gmx
    uint256 public tokenBallo=20;
    address public tokenC=0x912CE59144191C1204E64559FE8253a0e49E6548;//arb arb
    uint256 public tokenCallo=20;
    address public tokenD=0x0c880f6761F1af8d9Aa9C466984b80DAb9a8c9e8;//arb pendle
    uint256 public tokenDallo=20;
    address public tokenE=0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8;//arb  grail
    uint256 public tokenEallo=15;
    address public tokenF=0x3082CC23568eA640225c2467653dB90e9250AaA0;//arb  rdnt
    uint256 public tokenFallo=15;
    uint256 public minDeposit=1e15;
    
    address mathLib=0x19F51834817708F2da9Ac7D0cc3eAFF0b6Ed17D7;
    address tickLib=0x642e8455F280d1F5f252DFFE0A264810A80A7DF7;


    uint24 public tokenAFees=100;
    uint24 public tokenBFees=3000;
    uint24 public tokenCFees = 500;
    uint24 public tokenDFees = 3000;
    uint24 public tokenEFees = 10000;
    uint24 public tokenFFees = 3000;



    address protocol = 0x7c9d0356a3B50cF353e858C4D697cC5A5e468A03;
    address partner = 0x7c9d0356a3B50cF353e858C4D697cC5A5e468A03;
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
                weth,
                "Earth-WETH-Index-Vault",
                "Earth-WETH-Index-Vault",
                stratUpdateDelay,
                vaultTvlCap
            );
        CommonAddresses memory _commonAddresses = CommonAddresses(
            address(vault),
            router
        );


        EarthIndexParams memory _EarthParams =  EarthIndexParams(
            weth,
            factory,
            tokenA,
            tokenAallo,
            tokenB,
            tokenBallo,
            tokenC,
            tokenCallo,
            tokenD,
            tokenDallo,
            tokenE,
            tokenEallo,
            tokenF,
            tokenFallo,
            minDeposit
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

            LiberayParams memory liberayParam = LiberayParams(
            tickLib,
            mathLib
            );

            SwapFees memory feesP = SwapFees(
            tokenAFees,
            tokenBFees,
            tokenCFees,
            tokenDFees,
            tokenEFees,
            tokenFFees
            );

            EarthIndex strat = new EarthIndex(
                _commonAddresses,
                feesParams,
                _EarthParams,
                liberayParam,
                feesP
            );

            vault.init(IStrategy(address(strat)));
            console.log(address(strat));
            console.log(address(vault));
            vm.stopBroadcast();
     }
}
//  anvil --fork-url https://1rpc.io/arb  --mnemonic "disorder pretty oblige witness close face food stumble name material couch planet"

// forge script scripts/Deploy.s.sol:Deploy --rpc-url https://arbitrum.llamarpc.com --broadcast -vvv --legacy --slow
//127.0.0.1:8545
//0.00791152033125  7842895
