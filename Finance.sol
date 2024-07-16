// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./interfaces/IFinance.sol";

interface IRouter {

    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        returns (uint256[] memory amounts);
}
contract Finance is Initializable, AccessControlUpgradeable, IFinance {

    address public gamefiAdmin;
    address public usdt;
    address public wnovai;
    address public router;
    // uint256 public etfPercent;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    constructor() {
        _disableInitializers();
    }
    receive() external payable {}
    function initialize(address defaultAdmin,address _gamefiAdmin,address _usdt,address _wnovai,address _router) initializer public {
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, defaultAdmin);
        gamefiAdmin = _gamefiAdmin;
        usdt = _usdt;
        wnovai = _wnovai;
        router = _router;
    }
    function deposit(uint256 amount,uint256 usdtInput,uint256 novaiInput,uint256 usdtSwap) external payable returns(uint256){
        ERC20Upgradeable(usdt).transferFrom(msg.sender, address(this), usdtInput);
        
        ERC20Upgradeable(usdt).approve(router, usdtSwap);
        uint256[] memory amounts;
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = wnovai;
        uint256 swapOut;
        if(usdtSwap>0){
           amounts=IRouter(router).swapExactTokensForETH(usdtSwap, 0, path, address(this), block.timestamp + 1000);
           swapOut=amounts[1];
        }else{
           swapOut=0;
        }
        

        
        
        payable(gamefiAdmin).transfer(novaiInput+swapOut);
        ERC20Upgradeable(usdt).transfer(gamefiAdmin, usdtInput-usdtSwap);
        emit Deposit(msg.sender,amount,usdtInput-usdtSwap,novaiInput+swapOut);

        return 0;
    }

    function setGamefiAdmin(address _gamefiAdmin) external onlyRole(MINTER_ROLE) returns(bool){
        gamefiAdmin = _gamefiAdmin;
        return true;
    }
    function setUsdt(address _usdt) external onlyRole(MINTER_ROLE) returns(bool){
        usdt = _usdt;
        return true;
    }
}

