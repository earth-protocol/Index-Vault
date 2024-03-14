// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../../../src/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "../../../src/strategies/staking/EarthIndex.sol";
import "../../../src/strategies/common/interfaces/IStrategy.sol";
import "../../../src/strategies/staking/EarthIndex.sol";

contract EarthT is Test{
    address public vault = 0xcc08992d3E52FdfA79826E442910865E663fd710;
    address public token = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address public strat = 0x935EE143cE346e64ba1b89f5DBDBbF414655FB67;
    address public user=0x171cda359aa49E46Dec45F375ad6c256fdFBD420;

    address public userO = 0xFaBcc4b22fFEa25D01AC23c5d225D7B27CB1B6B8;


    address public router =0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;//arb univ3
    address public factory=0x1F98431c8aD98523631AE4a59f267346ea31F984; //arb univ3
    

    address public depositToken=0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;//arb usdc
    address public tokenA=0x912CE59144191C1204E64559FE8253a0e49E6548; //arb arb
    uint256 public tokenAallo=50;
    address public tokenB=0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;//arb gmx
    uint256 public tokenBallo=30;
    address public tokenC=0x3082CC23568eA640225c2467653dB90e9250AaA0;//arb rdnt
    uint256 public tokenCallo=20;
    address public tokenD=0x989686C23206b121DcFA70C0042B8Fc29d7770a7;
    uint256 public tokenDallo=15;
    uint256 public minDeposit=100e6;


    address public depositFeed =0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
    address public tokenAFeed=0xb2A824043730FE05F3DA2efaFa1CBbe83fa548D6;
    address public tokenBFeed=0xDB98056FecFff59D032aB628337A4887110df3dB;
    address public tokenCFeed=0x20d0Fcab0ECFD078B036b6CAf1FaC69A6453b352;
    uint256 public oracleDeci=8;

    uint24 public tokenAFees=500;
    uint24 public tokenBFees=3000;
    uint24 public tokenCFees = 10000;



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

    function setUp() public {
        uint privateKey = vm.envUint("PRIVATE_KEY");
        address acc = vm.addr(privateKey);
        console.log("Account", acc);

        vm.startPrank(acc);

          RiveraAutoCompoundingVaultV2Public vaultI = new RiveraAutoCompoundingVaultV2Public(
                depositToken,
                "Earth-USDC-Index-Vault",
                "Earth-USDC-Index-Vault",
                stratUpdateDelay,
                vaultTvlCap
            );
        CommonAddresses memory _commonAddresses = CommonAddresses(
            address(vaultI),
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
            tokenCallo,
            // tokenD,
            // tokenDallo
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

            OracleParams memory oracleParam = OracleParams(
            depositFeed,
            tokenAFeed,
            tokenBFeed,
            tokenCFeed,
            oracleDeci
            );

            SwapFees memory feesP = SwapFees(
            tokenAFees,
            tokenBFees,
            tokenCFees
            );

            EarthIndex stratI = new EarthIndex(
                _commonAddresses,
                feesParams,
                _EarthParams,
                oracleParam,
                feesP
            );

            vaultI.init(IStrategy(address(stratI)));
            vault = address(vaultI);
            strat = address(stratI);
            vm.stopPrank();
            console.log(strat);
            console.log(vault);
     }


     function test_deposit() public {
        vm.startPrank(user);
        uint256 depo = 3000e6;
        IERC20(token).approve(vault,10000e6);
        bool isW = IStrategy(strat).paused();
        console.log(isW);
        RiveraAutoCompoundingVaultV2Public(vault).deposit(depo,user);
        emit log_named_uint ("totalAsset ",EarthIndex(strat).balanceOf());
        emit log_named_uint ("totalAsset in A",EarthIndex(strat).balanceOfA());
        emit log_named_uint ("totalAsset in B",EarthIndex(strat).balanceOfB());
        emit log_named_uint ("totalAsset in C",EarthIndex(strat).balanceOfC());
        vm.stopPrank();
     }


     function test_withdraw() public {
        vm.startPrank(user);
        uint256 depo = 300e6;
        bool isW = IStrategy(strat).paused();
        console.log(isW);
        IERC20(token).approve(vault,10000e6);
        RiveraAutoCompoundingVaultV2Public(vault).deposit(depo*2,user);
        uint256 dp = RiveraAutoCompoundingVaultV2Public(vault).totalAssets();
        console.log("totalAsset after deposit",dp);
        console.log("balance is",IERC20(vault).balanceOf(user));
         depo =RiveraAutoCompoundingVaultV2Public(vault).maxWithdraw(user);
        RiveraAutoCompoundingVaultV2Public(vault).withdraw((depo/2),user,user);
        dp = RiveraAutoCompoundingVaultV2Public(vault).totalAssets();
        emit log_named_uint ("totalAsset after withdraw",dp);
        emit log_named_uint("balance is",IERC20(vault).balanceOf(user));
        emit log_named_uint ("totalAsset ",EarthIndex(strat).balanceOf());
        // emit log_named_uint ("totalAsset in A",EarthIndex(strat).balanceOfStakedA());
        // emit log_named_uint ("totalAsset in B",EarthIndex(strat).balanceOfStakedB());
        // emit log_named_uint ("totalAsset in C",EarthIndex(strat).balanceOfStakedC());
        vm.stopPrank();
     }

    //   function test_Rebalance() public {
    //     vm.startPrank(user);
    //     uint256 depo = 300e6;
    //     bool isW = IStrategy(strat).paused();
    //     console.log(isW);
    //     IERC20(token).approve(vault,10000e6);
    //     RiveraAutoCompoundingVaultV2Public(vault).deposit(depo*2,user);
    //     uint256 dp = RiveraAutoCompoundingVaultV2Public(vault).totalAssets();
    //     EarthIndex(strat).rebalance();
    //     vm.stopPrank();
    //  }
    }





//forge test --match-path test/strategies/staking/Earth.t.sol --fork-url https://arbitrum.llamarpc.com -vvvv