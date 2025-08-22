// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/interfaces/IERC20.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/utils/ReentrancyGuard.sol";
import { ECDSA } from "@openzeppelin/utils/cryptography/ECDSA.sol";
import { SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";

import { L1Vault } from "./L1Vault.sol";

contract L1BossBridge is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public DEPOSIT_LIMIT = 100_000 ether;

    IERC20 public immutable token;
    L1Vault public immutable vault;
    mapping(address account => bool isSigner) public signers;

    error L1BossBridge__DepositLimitReached();
    error L1BossBridge__Unauthorized();
    error L1BossBridge__CallFailed();

    event Deposit(address from, address to, uint256 amount);

    constructor(IERC20 _token) Ownable(msg.sender) {
        token = _token;
        vault = new L1Vault(token, address(this));
        // Permite que a bridge mova tokens do vault para facilitar withdrawals
        vault.approveTo(address(this), type(uint256).max);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setSigner(address account, bool enabled) external onlyOwner {
        signers[account] = enabled;
    }

    /*
     * @notice Trava tokens no vault e emite um evento Deposit
     * O serviço off-chain monitora este evento e cunha tokens correspondentes na L2
     * 
     * @param from Endereço do usuário que está depositando tokens
     * @param l2Recipient Endereço do usuário que receberá os tokens na L2
     * @param amount Quantidade de tokens a depositar
     */
    function depositTokensToL2(address from, address l2Recipient, uint256 amount) external whenNotPaused {
        if (token.balanceOf(address(vault)) + amount > DEPOSIT_LIMIT) {
            revert L1BossBridge__DepositLimitReached();
        }
        token.safeTransferFrom(from, address(vault), amount);

        // Nosso serviço off-chain captura este evento para cunhar tokens na L2
        emit Deposit(from, l2Recipient, amount);
    }

    /*
     * @notice Função responsável por sacar tokens da L2 para L1
     * @notice A assinatura é necessária para prevenir ataques de replay
     * 
     * @param to Endereço do usuário que receberá os tokens na L1
     * @param amount Quantidade de tokens a sacar
     * @param v Valor v da assinatura
     * @param r Valor r da assinatura
     * @param s Valor s da assinatura
     */
    function withdrawTokensToL1(address to, uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
        sendToL1(
            v,
            r,
            s,
            abi.encode(
                address(token),
                0, // value
                abi.encodeCall(IERC20.transferFrom, (address(vault), to, amount))
            )
        );
    }

    /*
     * @notice Função responsável por processar mensagens da L2 para L1
     *
     * @param v Valor v da assinatura
     * @param r Valor r da assinatura
     * @param s Valor s da assinatura
     * @param message Mensagem/dados a serem processados (pode estar em branco)
     */
    function sendToL1(uint8 v, bytes32 r, bytes32 s, bytes memory message) public nonReentrant whenNotPaused {
        // Implementação manual do Ethereum Signed Message hash
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(message)));
        address signer = ECDSA.recover(hash, v, r, s);

        if (!signers[signer]) {
            revert L1BossBridge__Unauthorized();
        }

        (address target, uint256 value, bytes memory data) = abi.decode(message, (address, uint256, bytes));

        (bool success,) = target.call{ value: value }(data);
        if (!success) {
            revert L1BossBridge__CallFailed();
        }
    }
}