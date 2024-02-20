pragma solidity ^0.8.0;

import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/security/Pausable.sol";
import "@openzeppelin/security/ReentrancyGuard.sol";

import "@pancakeswap-v2-exchange-protocol/interfaces/IPancakeRouter02.sol";
import "@pancakeswap-v2-core/interfaces/IPancakePair.sol";
import "./interfaces/ICommonStrat.sol";
import "./interfaces/IMasterChef.sol";
import "./interfaces/IPancakeFactory.sol";
import "../common/AbstractStrategy.sol";
import "../utils/StringUtils.sol";

struct EarthIndexParams{
   address tokenA;
   uint256 tokenAallo;
   address tokenB;
   uint256 tokenBallo;
   address tokenC;
   uint256 tokenCallo;
   address tokenD;
   uint256 tokenDallo;
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

contract EarthIndex is AbstractStrategy,ReentrancyGuard{
    using SafeERC20 for IERC20;
    
    address public tokenA;
    address public tokenB;
    address public tokenC;
    address public tokenD;

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

    constructor(
    CommonAddresses memory _commonAddresses,
    EarthFeesParams memory _EarthFeesParams,
    EarthIndexParams memory _EarthIndexParams
    ){
        tokenA = _EarthIndexParams.tokenA;
        allocations[tokenA] = _EarthIndexParams.tokenAallo;
        tokenB = _EarthIndexParams.tokenB;
        allocations[tokenB] = _EarthIndexParams.tokenBallo;
        tokenC = _EarthIndexParams.tokenC;
        allocations[tokenC] = _EarthIndexParams.tokenCallo;
        tokenD = _EarthIndexParams.tokenD;
        allocations[tokenD] = _EarthIndexParams.tokenDallo;

        protocol = _EarthFeesParams.protocol;
        partner = _EarthFeesParams.partner;
        protocolFee = _EarthFeesParams.protocolFee;
        partnerFee = _EarthFeesParams.partnerFee;
        fundManagerFee = _EarthFeesParams.fundManagerFee;
        feeDecimals = _EarthFeesParams.feeDecimals;
        withdrawFee = _EarthFeesParams.withdrawFee;
        withdrawFeeDecimals = _EarthFeesParams.withdrawFeeDecimals;   
    }

    function deposit() public whenNotPaused nonReentrant {
        onlyVault();
        _deposit();
    }

    function withdraw(uint256 _amount) public nonReentrant {
        onlyVault(); 
    }

    function retireStrat() external {
        onlyVault();
    }

    function harvest() public {}

    function balanceOf() public view returns(uint256){}

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

    }

    function _removeAllowances() internal virtual {
       
    }


}