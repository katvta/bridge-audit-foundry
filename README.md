# Boss Bridge

## Mecanismo simples para conectar blockchains (L1 → L2)

Este projeto implementa uma bridge unidirecional que permite a transferência de um token ERC20 da Layer 1 (Ethereum) para uma rede Layer 2. O foco está na parte on-chain da L1, onde os tokens são depositados e trancados. A lógica na L2 não está incluída neste repositório.

O fluxo de depósito é o seguinte:
1. O usuário chama `depositTokensToL2`, transferindo tokens para o `L1Vault`.
2. O contrato `L1BossBridge` emite um evento.
3. Um serviço off-chain monitora esse evento e aciona a cunhagem correspondente na L2.

---

## Mecanismos de Segurança

- O owner da bridge pode pausar as operações em situações de emergência.
- Depósitos são permissionless, mas limitados por transação.
- Saques (L2 → L1) requerem assinatura de um operador autorizado.

---

## Compatibilidade de Tokens

Apenas o contrato `L1Token.sol` ou cópias idênticas são suportadas. Tokens ERC20 com lógica personalizada (como taxas, rebase ou contas bloqueadas) não são compatíveis com esta implementação.

---

## Sobre Withdrawals

O processo de saque é gerenciado off-chain:
- O usuário submete uma solicitação na L2.
- O bridge operator valida se houve depósito prévio na L1.
- Se válido, o operador assina a liberação.
- Essa assinatura permite liberar os tokens trancados na L1.

O contrato L2 e o serviço de assinatura não estão incluídos neste repositório.

---

# Configuração do Ambiente

## 1. Git

Necessário para clonar o repositório.

**Instalação (Linux - Debian/Ubuntu):**
```bash
sudo apt update && sudo apt install git -y
```

**Verificação:**
```bash
git --version
```

## 2. Foundry (Forge, Anvil, Cast)

Kit de desenvolvimento para Solidity.

**Instalação:**
```bash
curl -L https://foundry.paradigm.xyz | bash
```

**Carregar no shell:**
```bash
source ~/.bashrc
```
ou
```bash
source ~/.zshrc
```

**Instalar Foundry:**
```bash
foundryup
```

**Verificação:**
```bash
forge --version
```

## 3. Python 3.11+

Usado para análise de segurança com Slither e Aderyn.

**Instalação (Debian/Ubuntu):**
```bash
sudo apt install python3.11 python3.11-venv python3.11-dev -y
```

**Verificação:**
```bash
python3.11 --version
```

---

# Inicialização do Projeto

```bash
git clone https://github.com/bridge-audit-foundry
cd bridge-audit-foundry
make
```

O comando `make` executa:
- Limpeza de submódulos
- Instalação de dependências
- Compilação dos contratos

Este é o comando para inicializar o projeto após o clone.

---

# Comandos Principais

## Testes
```bash
make test
```

## Cobertura de código
```bash
forge coverage
forge coverage --report debug
```

## Formatação de código
```bash
make format
```

## Estrutura do projeto
```bash
make scope
```

Exporta a estrutura para um arquivo:
```bash
make scopefile
```

## Nó local (Anvil)
```bash
make anvil
```

Inicia um nó local.

---

# Análise de Segurança

### Configurar ambiente
```bash
make setup-security-tools
```

Cria um ambiente virtual isolado e instala `slither-analyzer` e `aderyn`.

### Executar Slither
```bash
make slither
```

Utiliza o arquivo `slither.config.json` para configuração personalizada.

### Executar Aderyn
```bash
make aderyn
```

Utiliza o arquivo `aderyn.config.json` para configuração personalizada.

---

# Arquitetura

## Contratos (`./src/`)
- `L1BossBridge.sol`: Ponto de entrada para depósitos
- `L1Token.sol`: Token ERC20 exemplo
- `L1Vault.sol`: Armazena os tokens depositados
- `TokenFactory.sol`: Permite deploy de cópias de `L1Token`

**Versão do Solidity:** 0.8.20  

---

# Atores

- **Bridge Owner**: Responsável por pausar a bridge e definir signers.
- **Signer**: Autorizado a assinar saques (L2 → L1).
- **Vault**: Contrato que armazena os tokens depositados.
- **Usuários**: Chamam `depositTokensToL2()` para transferir da L1 para L2.

---

# Limitações Conhecidas

- Centralização: O owner possui poder total para pausar a bridge.
- Validações mínimas: Alguns checks de `address(0)` foram omitidos para reduzir custos de gás.
- Constantes hardcoded: Valores como limites e timeouts estão diretamente no código.
- Suposição de cópia fiel: Assume-se que `TokenFactory` cria cópias exatas de `L1Token.sol`, sem validação adicional.

---
