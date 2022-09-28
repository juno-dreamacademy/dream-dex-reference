// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

contract Dex is ERC20 {
    using SafeERC20 for IERC20;

    IERC20 _tokenX;
    IERC20 _tokenY;

    constructor(address tokenX, address tokenY) ERC20("DreamAcademy DEX LP token", "DA-DEX-LP") {
        require(tokenX != tokenY, "DA-DEX: Tokens should be different");

        _tokenX = IERC20(tokenX);
        _tokenY = IERC20(tokenY);
    }

    function swap(uint256 tokenXAmount, uint256 tokenYAmount, uint256 tokenMinimumOutputAmount)
        external
        returns (uint256 outputAmount)
    {
        // TODO
        return 0;
    }

    function addLiquidity(uint256 tokenXAmount, uint256 tokenYAmount, uint256 minimumLPTokenAmount)
        external
        returns (uint256 LPTokenAmount)
    {
        uint256 balanceX = _tokenX.balanceOf(address(this));
        uint256 balanceY = _tokenY.balanceOf(address(this));

        uint256 kBefore = balanceX * balanceY;
        uint256 kAfter = (balanceX + tokenXAmount) * (balanceY + tokenYAmount);

        uint256 liquidityBefore = balanceOf(address(this));

        uint256 liquidityAfter;
        if (liquidityBefore == 0 || kBefore == 0) {
            liquidityAfter = sqrt(kAfter);
        } else {
            liquidityAfter = liquidityBefore * kAfter / kBefore;
        }

        uint256 toMint = liquidityAfter - liquidityBefore;
        require(toMint >= minimumLPTokenAmount);

        _tokenX.safeTransferFrom(msg.sender, address(this), tokenXAmount);
        _tokenY.safeTransferFrom(msg.sender, address(this), tokenYAmount);
        _mint(msg.sender, toMint);

        return toMint;
    }

    function removeLiquidity(uint256 LPTokenAmount, uint256 minimumTokenXAmount, uint256 minimumTokenYAmount)
        external
    {
        uint256 liquidity = balanceOf(address(this));

        uint256 balanceX = _tokenX.balanceOf(address(this));
        uint256 balanceY = _tokenY.balanceOf(address(this));

        uint256 transferX = balanceX * LPTokenAmount / liquidity;
        uint256 transferY = balanceY * LPTokenAmount / liquidity;

        require(transferX >= minimumTokenXAmount);
        require(transferY >= minimumTokenYAmount);

        _burn(msg.sender, LPTokenAmount);
        _tokenX.safeTransfer(msg.sender, transferX);
        _tokenY.safeTransfer(msg.sender, transferY);
    }

    function sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
