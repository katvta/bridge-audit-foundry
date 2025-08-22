// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/interfaces/IERC20.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";

import { IERC20 } from "@openzeppelin/interfaces/IERC20.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";

/// @title L1Vault
/// @author Boss Bridge Peeps
/// @notice Este contrato é responsável por travar e destravar tokens na L1 ou L2
/// @notice Ele aprovará a bridge para mover fundos para dentro e para fora deste contrato
/// @notice Seu dono deve ser a bridge
contract L1Vault is Ownable {
    IERC20 public token;

    constructor(IERC20 _token, address initialOwner) Ownable(initialOwner) {
        token = _token;
    }

    function approveTo(address target, uint256 amount) external onlyOwner {
        token.approve(target, amount);
    }
}