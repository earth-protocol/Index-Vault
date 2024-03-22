pragma solidity ^0.8.0;

import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/security/Pausable.sol";
import "@openzeppelin/security/ReentrancyGuard.sol";

import "@pancakeswap-v2-exchange-protocol/interfaces/IPancakeRouter02.sol";
import "@pancakeswap-v2-core/interfaces/IPancakePair.sol";
import "./interfaces/IUniswapV3Factory.sol";
import "./interfaces/IUniswapV3PoolState.sol";
import "./interfaces/IV3SwapRouter.sol";
import "./interfaces/IPancakeFactory.sol";
import "./interfaces/ICommonStrat.sol";
import "./interfaces/AggregatorV3Interface.sol";

import "./libraries/IFullMath.sol";
import "./libraries/ITickMath.sol";

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
   address tokenD;
   uint256 tokenDallo;
   address tokenE;
   uint256 tokenEallo;
   address tokenF;
   uint256 tokenFallo;
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

struct LiberayParams{
    address tickMath;
    address fullMath;
}

struct SwapFees{
    uint24 tokenAFees;
    uint24 tokenBFees;
    uint24 tokenCFees;
    uint24 tokenDFees;
    uint24 tokenEFees;
    uint24 tokenFFees;
}

contract EarthIndex is AbstractStrategy,ReentrancyGuard{
    using SafeERC20 for IERC20;

    address public depositToken;
    address public factory;
    
    address public tokenA;
    address public tokenB;
    address public tokenC;
    address public tokenD;
    address public tokenE;
    address public tokenF;

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


    // math lib
    address public fullMath;
    address public tickMath;

    //swap fees 
    uint24 public tokenAFees;
    uint24 public tokenBFees;
    uint24 public tokenCFees;
    uint24 public tokenDFees;
    uint24 public tokenEFees;
    uint24 public tokenFFees;

    constructor(
    CommonAddresses memory _commonAddresses,
    EarthFeesParams memory _EarthFeesParams,
    EarthIndexParams memory _EarthIndexParams,
    LiberayParams memory _LiberayParams,
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
        tokenD = _EarthIndexParams.tokenD;
        allocations[tokenD] = _EarthIndexParams.tokenDallo;
        tokenE = _EarthIndexParams.tokenE;
        allocations[tokenE] = _EarthIndexParams.tokenEallo;
        tokenF = _EarthIndexParams.tokenF;
        allocations[tokenF] = _EarthIndexParams.tokenFallo;
        minDeposit = _EarthIndexParams.minDeposit;


        protocol = _EarthFeesParams.protocol;
        partner = _EarthFeesParams.partner;
        protocolFee = _EarthFeesParams.protocolFee;
        partnerFee = _EarthFeesParams.partnerFee;
        fundManagerFee = _EarthFeesParams.fundManagerFee;
        feeDecimals = _EarthFeesParams.feeDecimals;
        withdrawFee = _EarthFeesParams.withdrawFee;
        withdrawFeeDecimals = _EarthFeesParams.withdrawFeeDecimals;   
        
        tickMath = _LiberayParams.tickMath;
        fullMath = _LiberayParams.fullMath;

        tokenAFees = _SwapFees.tokenAFees;
        tokenBFees = _SwapFees.tokenBFees;
        tokenCFees = _SwapFees.tokenCFees;
        tokenDFees = _SwapFees.tokenDFees;
        tokenEFees = _SwapFees.tokenEFees;
        tokenFFees = _SwapFees.tokenFFees;
        
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
        uint256 depoD = (balance * (allocations[tokenD]))/100;
        _swapV3In(depositToken,tokenD,depoD,tokenDFees);
        uint256 depoE = (balance * (allocations[tokenE]))/100;
        _swapV3In(depositToken,tokenE,depoE,tokenEFees);
        uint256 depoF = (balance * (allocations[tokenF]))/100;
        _swapV3In(depositToken,tokenF,depoF,tokenFFees);
        }
        
    }
    

    function withdraw(uint256 _amount) public nonReentrant {
        onlyVault();
        uint256 balanceD = IERC20(depositToken).balanceOf(address(this));
        if(_amount > balanceD){
        withdrawRatio(_amount);
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
        uint256 balanceD = IERC20(tokenD).balanceOf(address(this));
        _swapV3In(tokenD,depositToken,balanceD,tokenDFees);
        uint256 balanceE = IERC20(tokenE).balanceOf(address(this));
        _swapV3In(tokenE,depositToken,balanceE,tokenEFees);
        uint256 balanceF = IERC20(tokenF).balanceOf(address(this));
        _swapV3In(tokenF,depositToken,balanceF,tokenFFees);
    }


    function withdrawRatio(uint256 _amount) internal {
      uint256 withdrawTokenA =tokenAToTokenBConversion(depositToken,tokenA,tokenAFees,(_amount*(balanceOfA() * 100/balanceOf()))/100);
      uint256 withdrawTokenB =tokenAToTokenBConversion(depositToken,tokenB,tokenBFees,(_amount*(balanceOfB()* 100/balanceOf()))/100);
      uint256 withdrawTokenC =tokenAToTokenBConversion(depositToken,tokenC,tokenCFees,(_amount*(balanceOfC()* 100/balanceOf()))/100);
      uint256 withdrawTokenD =tokenAToTokenBConversion(depositToken,tokenD,tokenDFees,(_amount*(balanceOfD()* 100/balanceOf()))/100);
      uint256 withdrawTokenE =tokenAToTokenBConversion(depositToken,tokenE,tokenEFees,(_amount*(balanceOfE()* 100/balanceOf()))/100);
      uint256 withdrawTokenF =tokenAToTokenBConversion(depositToken,tokenF,tokenFFees,(_amount*(balanceOfF()* 100/balanceOf()))/100);
      _swapV3In(tokenA,depositToken,withdrawTokenA,tokenAFees);
      _swapV3In(tokenB,depositToken,withdrawTokenB,tokenBFees);
      _swapV3In(tokenC,depositToken,withdrawTokenC,tokenCFees);
      _swapV3In(tokenD,depositToken,withdrawTokenD,tokenDFees);
      _swapV3In(tokenE,depositToken,withdrawTokenE,tokenEFees);
      _swapV3In(tokenF,depositToken,withdrawTokenF,tokenFFees);
    }


    function closeAll() internal {
      swapAll();
    }

    function rebalance() external {
        onlyManager();
        closeAll();
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
        closeAll();
        uint256 totalBal = IERC20(depositToken).balanceOf(address(this));
        IERC20(depositToken).transfer(vault, totalBal);
    }

    function harvest() public {}

    function balanceOf() public view returns(uint256){
        return balanceOfA() + balanceOfB() + balanceOfC() +balanceOfD()+balanceOfE()+balanceOfF() + balanceOfDepositToken();
    }


   function balanceOfA() public view returns(uint256){
        uint256 balA = IERC20(tokenA).balanceOf(address(this));
        return tokenAToTokenBConversion(tokenA,depositToken,tokenAFees,balA);  
   }
   
   function balanceOfB() public view returns(uint256){
        uint256 balB = IERC20(tokenB).balanceOf(address(this));
        return tokenAToTokenBConversion(tokenB,depositToken,tokenBFees,balB);
   }


   function balanceOfC() public view returns(uint256){
        uint256 balC = IERC20(tokenC).balanceOf(address(this));
        return tokenAToTokenBConversion(tokenC,depositToken,tokenCFees,balC);
   }

   function balanceOfD() public view returns(uint256){
        uint256 balD = IERC20(tokenD).balanceOf(address(this));
        return tokenAToTokenBConversion(tokenD,depositToken,tokenDFees,balD);
   }

   function balanceOfE() public view returns(uint256){
        uint256 balE = IERC20(tokenE).balanceOf(address(this));
        return tokenAToTokenBConversion(tokenE,depositToken,tokenEFees,balE);
   }

   function balanceOfF() public view returns(uint256){
        uint256 balF = IERC20(tokenF).balanceOf(address(this));
        return tokenAToTokenBConversion(tokenF,depositToken,tokenFFees,balF);
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
        address tokenY,
        uint24 xToyFees,
        uint256 amount
    ) public view returns (uint256) {
        address uPool = IUniswapV3Factory(factory).getPool(tokenX,tokenY,xToyFees);
        (,int24 tick,,,,,) = IUniswapV3PoolState(uPool).slot0();
        return getQuoteAtTick(tick,uint128(amount),tokenX,tokenY);
    }


    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) public view returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = ITickMathLib(tickMath).getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? IFullMathLib(fullMath).mulDiv(ratioX192, baseAmount, 1 << 192)
                : IFullMathLib(fullMath).mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = IFullMathLib(fullMath).mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
                ? IFullMathLib(fullMath).mulDiv(ratioX128, baseAmount, 1 << 128)
                : IFullMathLib(fullMath).mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }


     function panic() public {
        onlyManager();
        swapAll();
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
    IERC20(tokenD).approve(router,type(uint256).max);
    IERC20(tokenE).approve(router,type(uint256).max);
    IERC20(tokenF).approve(router,type(uint256).max);
    }

    function _removeAllowances() internal virtual {
    IERC20(depositToken).approve(router,0);
    IERC20(tokenA).approve(router,0);
    IERC20(tokenB).approve(router,0);
    IERC20(tokenC).approve(router,0);
    IERC20(tokenD).approve(router,0);
    IERC20(tokenE).approve(router,0);
    IERC20(tokenF).approve(router,0);
    }


}