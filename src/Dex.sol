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
        uint256 balanceX = _tokenX.balanceOf(address(this));
        uint256 balanceY = _tokenY.balanceOf(address(this));

        uint256 k = balanceX * balanceY;

        require(k != 0);

        if (tokenXAmount == 0) {
            // exchange Y to X
            uint256 yAfter = balanceY + tokenYAmount;
            uint256 xAfter = k / yAfter;

            // Takes 0.1% fee, ignoring off-by-one
            // (attack usually not profitable due to gas price)
            uint256 xOut = (balanceX - xAfter) * 999 / 1000;
            require(xOut >= tokenMinimumOutputAmount);

            _tokenY.safeTransferFrom(msg.sender, address(this), tokenYAmount);
            _tokenX.safeTransfer(msg.sender, xOut);

            return xOut;
        } else if (tokenYAmount == 0) {
            // exchange X to Y
            uint256 xAfter = balanceX + tokenXAmount;
            uint256 yAfter = k / xAfter;

            // Takes 0.1% fee, ignoring off-by-one
            // (attack usually not profitable due to gas price)
            uint256 yOut = (balanceY - yAfter) * 999 / 1000;
            require(yOut >= tokenMinimumOutputAmount);

            _tokenX.safeTransferFrom(msg.sender, address(this), tokenXAmount);
            _tokenY.safeTransfer(msg.sender, yOut);

            return yOut;
        } else {
            revert("DA-DEX: X or Y should be 0");
        }
    }

    function addLiquidity(uint256 tokenXAmount, uint256 tokenYAmount, uint256 minimumLPTokenAmount)
        external
        returns (uint256 LPTokenAmount)
    {
        uint256 xBefore = _tokenX.balanceOf(address(this));
        uint256 yBefore = _tokenY.balanceOf(address(this));

        uint256 xAfter = xBefore + tokenXAmount;
        uint256 yAfter = yBefore + tokenYAmount;

        uint256 kBefore = xBefore * yBefore;
        uint256 kAfter = xAfter * yAfter;

        uint256 liquidityBefore = totalSupply();

        uint256 liquidityAfter;
        if (liquidityBefore == 0 || kBefore == 0) {
            liquidityAfter = sqrt(kAfter);
        } else {
            uint256 liquidityAfterWithX = liquidityBefore * xAfter / xBefore;
            uint256 liquidityAfterWithY = liquidityBefore * yAfter / yBefore;

            if (liquidityAfterWithX <= liquidityAfterWithY) {
                liquidityAfter = liquidityAfterWithX;
            } else {
                liquidityAfter = liquidityAfterWithY;
            }
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
        require(LPTokenAmount <= balanceOf(msg.sender));

        uint256 liquidity = totalSupply();

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

    // From UniSwap core
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
