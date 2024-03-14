pragma solidity ^0.8.0;

import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/security/Pausable.sol";
import "@openzeppelin/security/ReentrancyGuard.sol";

import "@pancakeswap-v2-exchange-protocol/interfaces/IPancakeRouter02.sol";
import "@pancakeswap-v2-core/interfaces/IPancakePair.sol";
import "./interfaces/IV3SwapRouter.sol";
import "./interfaces/IPancakeFactory.sol";
import "./interfaces/ICommonStrat.sol";
import "./interfaces/AggregatorV3Interface.sol";

import "../common/AbstractStrategy.sol";
import "../utils/StringUtils.sol";

struct EarthIndexParams{
   address depositToken;
   address factory;
   address tokenA;
   uint256 tokenAallo;
   address tokenB;
   uint256 tokenBallo;
   address tokenC;
   uint256 tokenCallo;
//    address tokenD;
//    uint256 tokenDallo;
   uint256 minDeposit;
}

 struct EarthFeesParams {
    address protocol;
    address partner;
    uint256 protocolFee;
    uint256 partnerFee;
    uint256 fundManagerFee;
    uint256 feeDecimals;
    uint256 withdrawFee;
    uint256 withdrawFeeDecimals;
}

struct OracleParams{
    address depositFeed;
    address tokenAFeed;
    address tokenBFeed;
    address tokenCFeed;
    uint256 oracledDeci;
}

struct SwapFees{
    uint24 tokenAFees;
    uint24 tokenBFees;
    uint24 tokenCFees;
}

contract EarthIndex is AbstractStrategy,ReentrancyGuard{
    using SafeERC20 for IERC20;

    address public depositToken;
    address public factory;
    
    address public tokenA;
    address public tokenB;
    address public tokenC;
    address public tokenD;

    uint256 public minDeposit;

  mapping (address => uint) public allocations;

    //Fees Parameters
    address public protocol;
    address public partner;
    uint256 public protocolFee;
    uint256 public partnerFee;
    uint256 public fundManagerFee;
    uint256 public feeDecimals;
    uint256 public withdrawFee;
    uint256 public withdrawFeeDecimals;

    //Oracle Parameters
    address public depositFeed;
    address public tokenAFeed;
    address public tokenBFeed;
    address public tokenCFeed;
    uint256 public oracleDeci;

    //swap fees 
    uint24 public tokenAFees;
    uint24 public tokenBFees;
    uint24 public tokenCFees;

    constructor(
    CommonAddresses memory _commonAddresses,
    EarthFeesParams memory _EarthFeesParams,
    EarthIndexParams memory _EarthIndexParams,
    OracleParams memory _OracleParams,
    SwapFees memory _SwapFees
    )AbstractStrategy(_commonAddresses){
        depositToken = _EarthIndexParams.depositToken;
        factory = _EarthIndexParams.factory;

        tokenA = _EarthIndexParams.tokenA;
        allocations[tokenA] = _EarthIndexParams.tokenAallo;
        tokenB = _EarthIndexParams.tokenB;
        allocations[tokenB] = _EarthIndexParams.tokenBallo;
        tokenC = _EarthIndexParams.tokenC;
        allocations[tokenC] = _EarthIndexParams.tokenCallo;
        minDeposit = _EarthIndexParams.minDeposit;


        protocol = _EarthFeesParams.protocol;
        partner = _EarthFeesParams.partner;
        protocolFee = _EarthFeesParams.protocolFee;
        partnerFee = _EarthFeesParams.partnerFee;
        fundManagerFee = _EarthFeesParams.fundManagerFee;
        feeDecimals = _EarthFeesParams.feeDecimals;
        withdrawFee = _EarthFeesParams.withdrawFee;
        withdrawFeeDecimals = _EarthFeesParams.withdrawFeeDecimals;   
        
        depositFeed = _OracleParams.depositFeed;
        tokenAFeed = _OracleParams.tokenAFeed;
        tokenBFeed = _OracleParams.tokenBFeed;
        tokenCFeed = _OracleParams.tokenCFeed;
        oracleDeci = _OracleParams.oracledDeci;

        tokenAFees = _SwapFees.tokenAFees;
        tokenBFees = _SwapFees.tokenBFees;
        tokenCFees = _SwapFees.tokenCFees;
        
        _giveAllowances();
    }

    function deposit() public whenNotPaused nonReentrant {
        onlyVault();
        _deposit();
    }

    function _deposit() internal{
        uint256 balance = IERC20(depositToken).balanceOf(address(this));
        if(balance > minDeposit){
        uint256 depoA = (balance * (allocations[tokenA]))/100;
        _swapV3In(depositToken,tokenA,depoA,tokenAFees);
        uint256 depoB = (balance * (allocations[tokenB]))/100;
        _swapV3In(depositToken,tokenB,depoB,tokenBFees);
        uint256 depoC = (balance * (allocations[tokenC]))/100;
        _swapV3In(depositToken,tokenC,depoC,tokenCFees);
        }
        
    }
    

    function withdraw(uint256 _amount) public nonReentrant {
        onlyVault();
        uint256 balanceD = IERC20(depositToken).balanceOf(address(this));
        if(_amount > balanceD){
        withdrawRatio(_amount);
        swapAll();
        balanceD = IERC20(depositToken).balanceOf(address(this));
        if(balanceD < _amount){
            _amount = balanceD;
        }
        }
        IERC20(depositToken).safeTransfer(vault,_amount);
    }

    function swapAll() internal{
        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        _swapV3In(tokenA,depositToken,balanceA,tokenAFees);
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));
        _swapV3In(tokenB,depositToken,balanceB,tokenBFees);
        uint256 balanceC = IERC20(tokenC).balanceOf(address(this));
        _swapV3In(tokenC,depositToken,balanceC,tokenCFees);
    }


    function withdrawRatio(uint256 _amount) internal {
      uint256 withdrawTokenA =tokenAToTokenBConversion(depositToken,depositFeed,tokenA,tokenAFeed,(_amount*allocations[tokenA])/100);
      uint256 withdrawTokenB =tokenAToTokenBConversion(depositToken,depositFeed,tokenB,tokenBFeed,(_amount*allocations[tokenB])/100);
      uint256 withdrawTokenC =tokenAToTokenBConversion(depositToken,depositFeed,tokenC,tokenCFeed,(_amount*allocations[tokenC])/100);
      _swapV3In(depositToken,tokenA,withdrawTokenA,tokenAFees);
      _swapV3In(depositToken,tokenB,withdrawTokenB,tokenBFees);
      _swapV3In(depositToken,tokenC,withdrawTokenC,tokenCFees);
    }


    function clossAll() internal {
      swapAll();
    }

    function rebalance() external {
        onlyManager();
        clossAll();
        _deposit();
    }



     function _swapV2(address token0, address token1, uint256 _amount) internal {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        IPancakeRouter02(router).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp * 2
        );
    }

     function _swapV3In(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint24 fee
    ) internal returns (uint256 amountOut) {
        amountOut = IV3SwapRouter(router).exactInputSingle(
            IV3SwapRouter.ExactInputSingleParams(
                tokenIn,
                tokenOut,
                fee,
                address(this),
                amountIn,
                0,
                0
            )
        );
    }


    function retireStrat() external {
        onlyVault();
    }

    function harvest() public {}

    function balanceOf() public view returns(uint256){
        return balanceOfA() + balanceOfB() + balanceOfC() + balanceOfDepositToken();
    }


   function balanceOfA() public view returns(uint256){
        uint256 balA = IERC20(tokenA).balanceOf(address(this));
        return tokenAToTokenBConversion(tokenA,tokenAFeed,depositToken,depositFeed,balA);  
   }
   
   function balanceOfB() public view returns(uint256){
        uint256 balB = IERC20(tokenB).balanceOf(address(this));
        return tokenAToTokenBConversion(tokenB,tokenBFeed,depositToken,depositFeed,balB);
   }


   function balanceOfC() public view returns(uint256){
        uint256 balC = IERC20(tokenC).balanceOf(address(this));
        return tokenAToTokenBConversion(tokenC,tokenCFeed,depositToken,depositFeed,balC);
   }


    function balanceOfDepositToken() public view returns(uint256){
        uint256 balT = IERC20(depositToken).balanceOf(address(this));
        return balT;
    }

    function inCaseTokensGetStuck(address _token) external {
        onlyManager();
        uint256 amount = IERC20(_token).balanceOf(address(this)); //Just finding the balance of this vault contract address in the the passed baseToken and transfers
        IERC20(_token).transfer(msg.sender, amount);
    }


    function _chargeFees(address _token) internal {
        uint256 tokenBal = IERC20(_token).balanceOf(address(this));

        uint256 protocolFeeAmount = (tokenBal * protocolFee) / feeDecimals;
        IERC20(_token).safeTransfer(manager, protocolFeeAmount);

        uint256 fundManagerFeeAmount = (tokenBal * fundManagerFee) /
            feeDecimals;
        IERC20(_token).safeTransfer(owner(), fundManagerFeeAmount);

        uint256 partnerFeeAmount = (tokenBal * partnerFee) / feeDecimals;
        IERC20(_token).safeTransfer(partner, partnerFeeAmount);
    }

    function tokenAToTokenBConversion(
        address tokenX,
        address tokenXFeed,
        address tokenY,
        address tokenYFeed,
        uint256 amount
    ) public view returns (uint256) {
        uint256 aDec = IERC20Metadata(tokenX).decimals();
        uint256 bDec = IERC20Metadata(tokenY).decimals();

        (,int256 tokenXPrice,,,) = AggregatorV3Interface(tokenXFeed).latestRoundData();

        (,int256 tokenYPrice,,,) = AggregatorV3Interface(tokenYFeed).latestRoundData();

        uint256 amountXinUSD = ((10 ** aDec) * (10 ** oracleDeci)) /
            uint256(tokenXPrice); // X in 1 usd

        uint256 amountYinUSD = ((10 ** bDec) * (10 ** oracleDeci)) /
            uint256(tokenYPrice); // Y in 1 USD

        uint256 amountYinA = (amountYinUSD * (10 ** aDec)) / amountXinUSD; // amount of Y in 1 X token

        return (amountYinA * amount) / (10 ** aDec);
    }


     function panic() public {
        onlyManager();
        pause();
    }

    function pause() public {
        onlyManager();
        _pause();

        _removeAllowances();
    }

    function unpause() external {
        onlyManager();
        _unpause();

        _giveAllowances();

        _deposit();
    }

    function _giveAllowances() internal virtual {
    IERC20(depositToken).approve(router,type(uint256).max);
    IERC20(tokenA).approve(router,type(uint256).max);
    IERC20(tokenB).approve(router,type(uint256).max);
    IERC20(tokenC).approve(router,type(uint256).max);

    //IERC20(tokenD).approve(router,type(uint256).max);
    }

    function _removeAllowances() internal virtual {
    IERC20(depositToken).approve(router,0);
    IERC20(tokenA).approve(router,0);
    IERC20(tokenB).approve(router,0);
    IERC20(tokenC).approve(router,0);
    //IERC20(tokenD).approve(router,0);
    }


}