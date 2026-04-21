#!/bin/bash


# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    Script de Criação do Banco de Dados LACIQ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

# Verificar se o banco já existe
echo -e "${YELLOW}➜ Verificando se o banco de dados já existe...${NC}"
export PGPASSWORD="$DB_PASSWORD"
DB_EXISTS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$SUPER_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'")

if [ "$DB_EXISTS" = "1" ]; then
    echo -e "${RED}⚠ ATENÇÃO: O banco de dados '$DB_NAME' já existe!${NC}"
    read -p "Deseja recriá-lo? (s/N): " recreate
    if [[ ! "$recreate" =~ ^[Ss]$ ]]; then
        echo -e "${YELLOW}Operação cancelada.${NC}"
        exit 0
    fi
    
    echo -e "${YELLOW}Removendo banco existente...${NC}"
    dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$SUPER_USER" --if-exists "$DB_NAME"
fi

# Verificar se o usuário já existe
USER_EXISTS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$SUPER_USER" -d postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'")

if [ "$USER_EXISTS" = "1" ]; then
    echo -e "${YELLOW}⚠ Usuário '$DB_USER' já existe. Removendo...${NC}"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$SUPER_USER" -d postgres -c "DROP OWNED BY \"$DB_USER\";" 2>/dev/null
    dropuser -h "$DB_HOST" -p "$DB_PORT" -U "$SUPER_USER" --if-exists "$DB_USER"
fi

echo
echo -e "${GREEN}✓ Verificações concluídas${NC}"
echo

# 1. Criar o usuário
echo -e "${YELLOW}➜ Criando usuário '$DB_USER'...${NC}"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$SUPER_USER" -d postgres <<EOF
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Usuário criado com sucesso${NC}"
else
    echo -e "${RED}✗ Erro ao criar usuário${NC}"
    exit 1
fi

# 2. Criar o banco de dados com owner específico
echo -e "${YELLOW}➜ Criando banco de dados '$DB_NAME'...${NC}"
createdb -h "$DB_HOST" -p "$DB_PORT" -U "$SUPER_USER" -O "$DB_USER" "$DB_NAME"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Banco de dados criado com sucesso${NC}"
else
    echo -e "${RED}✗ Erro ao criar banco de dados${NC}"
    exit 1
fi

# 3. Conectar ao novo banco e configurar permissões
echo -e "${YELLOW}➜ Configurando permissões e privilégios...${NC}"

psql -h "$DB_HOST" -p "$DB_PORT" -U "$SUPER_USER" -d "$DB_NAME" <<EOF
-- Garantir que o schema public existe
CREATE SCHEMA IF NOT EXISTS public;

-- Conceder todas as permissões no schema public
GRANT ALL ON SCHEMA public TO $DB_USER;

-- Alterar owner do schema public
ALTER SCHEMA public OWNER TO $DB_USER;

-- Configurar permissões padrão para futuras tabelas
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO $DB_USER;

-- Garantir que o usuário tem todas as permissões em objetos existentes
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO $DB_USER;

-- Conceder permissões de conexão e criação
GRANT CONNECT ON DATABASE $DB_NAME TO $DB_USER;
GRANT CREATE ON DATABASE $DB_NAME TO $DB_USER;

-- Conceder permissões no schema public para criação de objetos
GRANT USAGE, CREATE ON SCHEMA public TO $DB_USER;
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Permissões configuradas com sucesso${NC}"
else
    echo -e "${RED}✗ Erro ao configurar permissões${NC}"
    exit 1
fi

# 4. Testar conexão com o novo usuário
echo -e "${YELLOW}➜ Testando conexão com o usuário '$DB_USER'...${NC}"
export PGPASSWORD="$DB_PASSWORD"
TEST_CONNECTION=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT 'Conexão bem-sucedida!' AS status")

if [ "$TEST_CONNECTION" = "Conexão bem-sucedida!" ]; then
    echo -e "${GREEN}✓ Conexão testada com sucesso${NC}"
else
    echo -e "${RED}✗ Falha no teste de conexão${NC}"
    exit 1
fi

# Limpar variável de ambiente
unset PGPASSWORD

echo
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ BANCO DE DADOS CRIADO COM SUCESSO!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo
echo -e "${BLUE}Resumo da configuração:${NC}"
echo "  • Banco de dados: $DB_NAME"
echo "  • Usuário: $DB_USER"
echo "  • Senha: **********"
echo "  • Host: $DB_HOST:$DB_PORT"
echo
echo -e "${BLUE}Permissões concedidas:${NC}"
echo "  ✓ CREATE USER com senha"
echo "  ✓ GRANT ALL ON SCHEMA public"
echo "  ✓ ALTER SCHEMA public OWNER"
echo "  ✓ GRANT ALL PRIVILEGES ON ALL TABLES"
echo "  ✓ GRANT ALL PRIVILEGES ON ALL SEQUENCES"
echo "  ✓ GRANT ALL PRIVILEGES ON ALL FUNCTIONS"
echo "  ✓ Permissões padrão configuradas"
echo
echo -e "${GREEN}Para conectar ao banco de dados:${NC}"
echo "  psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME"
echo
echo -e "${YELLOW}Nota: Use o script de 'down' para remover este ambiente quando necessário.${NC}"
# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    Script de Criação do Banco de Dados LACIQ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

# Verificar se o banco já existe
echo -e "${YELLOW}➜ Verificando se o banco de dados já existe...${NC}"
export PGPASSWORD="$DB_PASSWORD"
DB_EXISTS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$SUPER_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'")

if [ "$DB_EXISTS" = "1" ]; then
    echo -e "${RED}⚠ ATENÇÃO: O banco de dados '$DB_NAME' já existe!${NC}"
    read -p "Deseja recriá-lo? (s/N): " recreate
    if [[ ! "$recreate" =~ ^[Ss]$ ]]; then
        echo -e "${YELLOW}Operação cancelada.${NC}"
        exit 0
    fi
    
    echo -e "${YELLOW}Removendo banco existente...${NC}"
    dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$SUPER_USER" --if-exists "$DB_NAME"
fi

# Verificar se o usuário já existe
USER_EXISTS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$SUPER_USER" -d postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'")

if [ "$USER_EXISTS" = "1" ]; then
    echo -e "${YELLOW}⚠ Usuário '$DB_USER' já existe. Removendo...${NC}"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$SUPER_USER" -d postgres -c "DROP OWNED BY \"$DB_USER\";" 2>/dev/null
    dropuser -h "$DB_HOST" -p "$DB_PORT" -U "$SUPER_USER" --if-exists "$DB_USER"
fi

echo
echo -e "${GREEN}✓ Verificações concluídas${NC}"
echo

# 1. Criar o usuário
echo -e "${YELLOW}➜ Criando usuário '$DB_USER'...${NC}"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$SUPER_USER" -d postgres <<EOF
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Usuário criado com sucesso${NC}"
else
    echo -e "${RED}✗ Erro ao criar usuário${NC}"
    exit 1
fi

# 2. Criar o banco de dados com owner específico
echo -e "${YELLOW}➜ Criando banco de dados '$DB_NAME'...${NC}"
createdb -h "$DB_HOST" -p "$DB_PORT" -U "$SUPER_USER" -O "$DB_USER" "$DB_NAME"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Banco de dados criado com sucesso${NC}"
else
    echo -e "${RED}✗ Erro ao criar banco de dados${NC}"
    exit 1
fi

# 3. Conectar ao novo banco e configurar permissões
echo -e "${YELLOW}➜ Configurando permissões e privilégios...${NC}"

psql -h "$DB_HOST" -p "$DB_PORT" -U "$SUPER_USER" -d "$DB_NAME" <<EOF
-- Garantir que o schema public existe
CREATE SCHEMA IF NOT EXISTS public;

-- Conceder todas as permissões no schema public
GRANT ALL ON SCHEMA public TO $DB_USER;

-- Alterar owner do schema public
ALTER SCHEMA public OWNER TO $DB_USER;

-- Configurar permissões padrão para futuras tabelas
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO $DB_USER;

-- Garantir que o usuário tem todas as permissões em objetos existentes
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO $DB_USER;

-- Conceder permissões de conexão e criação
GRANT CONNECT ON DATABASE $DB_NAME TO $DB_USER;
GRANT CREATE ON DATABASE $DB_NAME TO $DB_USER;

-- Conceder permissões no schema public para criação de objetos
GRANT USAGE, CREATE ON SCHEMA public TO $DB_USER;
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Permissões configuradas com sucesso${NC}"
else
    echo -e "${RED}✗ Erro ao configurar permissões${NC}"
    exit 1
fi

# 4. Testar conexão com o novo usuário
echo -e "${YELLOW}➜ Testando conexão com o usuário '$DB_USER'...${NC}"
export PGPASSWORD="$DB_PASSWORD"
TEST_CONNECTION=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT 'Conexão bem-sucedida!' AS status")

if [ "$TEST_CONNECTION" = "Conexão bem-sucedida!" ]; then
    echo -e "${GREEN}✓ Conexão testada com sucesso${NC}"
else
    echo -e "${RED}✗ Falha no teste de conexão${NC}"
    exit 1
fi

# Limpar variável de ambiente
unset PGPASSWORD

echo
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ BANCO DE DADOS CRIADO COM SUCESSO!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo
echo -e "${BLUE}Resumo da configuração:${NC}"
echo "  • Banco de dados: $DB_NAME"
echo "  • Usuário: $DB_USER"
echo "  • Senha: **********"
echo "  • Host: $DB_HOST:$DB_PORT"
echo
echo -e "${BLUE}Permissões concedidas:${NC}"
echo "  ✓ CREATE USER com senha"
echo "  ✓ GRANT ALL ON SCHEMA public"
echo "  ✓ ALTER SCHEMA public OWNER"
echo "  ✓ GRANT ALL PRIVILEGES ON ALL TABLES"
echo "  ✓ GRANT ALL PRIVILEGES ON ALL SEQUENCES"
echo "  ✓ GRANT ALL PRIVILEGES ON ALL FUNCTIONS"
echo "  ✓ Permissões padrão configuradas"
echo
echo -e "${GREEN}Para conectar ao banco de dados:${NC}"
echo "  psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME"
echo
echo -e "${YELLOW}Nota: Use o script de 'down' para remover este ambiente quando necessário.${NC}"