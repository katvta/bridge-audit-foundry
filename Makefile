-include .env

# Força o uso do Bash, necessário para certas funcionalidades de shell
SHELL := /bin/bash

.PHONY: all test clean deploy fund help install snapshot format anvil scopefile setup-security-tools slither aderyn

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

all: remove install build test slither aderyn

help:
	@echo "Uso:"
	@echo "  make deploy ARGS=..."
	@echo "    Exemplo: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund ARGS=..."
	@echo "    Exemplo: make fund ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make setup-security-tools"
	@echo "    Configura um ambiente virtual para ferramentas de análise de segurança"
	@echo ""
	@echo "  make slither"
	@echo "    Executa análise de segurança com Slither"
	@echo ""
	@echo "  make aderyn"
	@echo "    Executa análise de segurança com Aderyn"

# Limpa o repositório
clean:
	forge clean

# Remove submódulos de forma segura
remove:
	@echo "Removendo submódulos de forma segura..."
	-git submodule deinit -f .
	-git rm -f lib
	-rm -rf lib .git/modules
	> .gitmodules
	git add .gitmodules
	@if git diff-index --cached --quiet HEAD -- .gitmodules; then \
		echo "Nenhuma alteração para comitar (configuração de submódulos já limpa)"; \
	else \
		git commit -m "chore: remove submodules and reset config"; \
		echo "Commit criado: 'chore: remove submodules and reset config'"; \
	fi
	@echo "Submódulos removidos com sucesso."

# Instala dependências
install:
	@echo "Instalando dependências..."
	forge install foundry-rs/forge-std
	forge install openzeppelin/openzeppelin-contracts
	@echo "Dependências instaladas."

# Atualiza dependências
update:
	@echo "Atualizando dependências..."
	forge update
	@echo "Dependências atualizadas."

# Compila o projeto
build:
	@echo "Compilando o projeto..."
	forge build
	@echo "Compilação concluída."

# Executa os testes
test:
	@echo "Executando testes..."
	forge test $(ARGS)
	@echo "Testes concluídos."

# Executa snapshot de testes
snapshot:
	@echo "Gerando snapshot..."
	forge snapshot $(ARGS)
	@echo "Snapshot concluído."

# Formata o código Solidity
format:
	@echo "Formatando código..."
	forge fmt
	@echo "Código formatado."

# Inicia um nó local com Anvil
anvil:
	@echo "Iniciando nó local com Anvil..."
	anvil -m 'test test test test test test test test test test test junk' \
		--steps-tracing \
		--block-time 1 \
		--accounts 10 \
		--balance 1000
	@echo "Anvil em execução."

# Faz o deploy dos contratos
deploy:
	@echo "Realizando deploy dos contratos..."
	@forge script script/Deploy.s.sol:Deploy --rpc-url $(shell forge config --get rpc_endpoints.ethereum.sepolia) $(ARGS) --broadcast --verify
	@echo "Deploy concluído."

# Envia ether para um endereço
fund:
	@echo "Enviando ether para o endereço $(ADDRESS)..."
	@cast send $(ADDRESS) --value $(AMOUNT) --rpc-url $(shell forge config --get rpc_endpoints.ethereum.sepolia) $(ARGS)
	@echo "Funding concluído."

# Configura ambiente para ferramentas de segurança (Slither + Aderyn)
setup-security-tools:
	@echo "Configurando ambiente para ferramentas de análise de segurança..."
	@mkdir -p $$HOME/security-tools
	@if [ ! -d "$$HOME/security-tools/slither-env" ]; then \
		echo "Criando ambiente virtual Python..."; \
		python3.11 -m venv $$HOME/security-tools/slither-env || \
		python3 -m venv $$HOME/security-tools/slither-env; \
	fi
	@echo "Ambiente virtual criado."
	@echo "Instalando Slither e Aderyn..."
	@. $$HOME/security-tools/slither-env/bin/activate && \
	pip install --upgrade pip && \
	pip install slither-analyzer aderyn
	@echo "Ferramentas de segurança instaladas com sucesso."
	@echo ""
	@echo "Para ativar o ambiente em sessões futuras, execute:"
	@echo "source $$HOME/security-tools/slither-env/bin/activate"

# Executa análise com Slither
slither:
	@if [ ! -d "$$HOME/security-tools/slither-env" ]; then \
		echo "Erro: ambiente de segurança não encontrado. Execute 'make setup-security-tools' primeiro."; \
		exit 1; \
	fi
	@echo "Executando análise com Slither..."
	@. $$HOME/security-tools/slither-env/bin/activate && \
	slither . --config-file slither.config.json || true
	@echo "Análise com Slither concluída."

# Executa análise com Aderyn
aderyn:
	@if [ ! -d "$$HOME/security-tools/slither-env" ]; then \
		echo "Erro: ambiente de segurança não encontrado. Execute 'make setup-security-tools' primeiro."; \
		exit 1; \
	fi
	@echo "Executando análise com Aderyn..."
	@if [ -f "$$HOME/security-tools/slither-env/bin/aderyn" ]; then \
		$$HOME/security-tools/slither-env/bin/aderyn . --config aderyn.config.json || true; \
	else \
		echo "Aviso: Aderyn não está instalado no ambiente virtual. Execute 'make setup-security-tools' novamente."; \
	fi
	@echo "Análise com Aderyn concluída."

# Exibe a estrutura do projeto
scope:
	@echo "Estrutura do projeto (src/):"
	tree ./src/ | sed 's/└/#/g; s/──/--/g; s/├/#/g; s/│ /|/g; s/│/|/g'

# Exporta a estrutura do projeto para scope.txt
scopefile:
	@echo "Exportando estrutura do projeto para scope.txt..."
	@tree ./src/ | sed 's/└/#/g' | awk -F '── ' '!/\.sol$$/ { path[int((length($$0) - length($$2))/2)] = $$2; next } { p = "src"; for(i=2; i<=int((length($$0) - length($$2))/2); i++) if (path[i] != "") p = p "/" path[i]; print p "/" $$2; }' > scope.txt
	@echo "Estrutura salva em scope.txt."