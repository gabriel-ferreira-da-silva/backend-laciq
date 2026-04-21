#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}⚠️  ATENÇÃO: Este script irá DERRUBAR (REMOVER) o banco de dados '$DB_NAME' e o usuário '$DB_USER'${NC}"
echo -e "${RED}Esta ação é IRREVERSÍVEL!${NC}"
echo
read -p "Tem certeza que deseja continuar? (digite 'SIM' para confirmar): " confirmation

if [ "$confirmation" != "SIM" ]; then
    echo -e "${YELLOW}Operação cancelada.${NC}"
    exit 0
fi

echo
echo -e "${YELLOW}Iniciando remoção...${NC}"

# Exportar senha para evitar prompt
export PGPASSWORD="$DB_PASSWORD"

# 1. Forçar término de todas as conexões ativas com o banco de dados
echo -e "${YELLOW}➜ Forçando término de conexões ativas com o banco...${NC}"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "
    SELECT pg_terminate_backend(pid)
    FROM pg_stat_activity
    WHERE datname = '$DB_NAME'
    AND pid <> pg_backend_pid();
" 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Conexões encerradas${NC}"
else
    echo -e "${YELLOW}⚠ Nenhuma conexão ativa ou banco já não existe${NC}"
fi

# 2. Remover o banco de dados
echo -e "${YELLOW}➜ Removendo banco de dados '$DB_NAME'...${NC}"
dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" --if-exists "$DB_NAME" 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Banco de dados removido com sucesso${NC}"
else
    echo -e "${RED}✗ Erro ao remover banco de dados (pode já não existir)${NC}"
fi

# 3. Remover o usuário/role
echo -e "${YELLOW}➜ Removendo usuário '$DB_USER'...${NC}"

# Primeiro, revogar privilégios e reassignar objetos (se houver)
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "
    REASSIGN OWNED BY \"$DB_USER\" TO postgres;
    DROP OWNED BY \"$DB_USER\";
" 2>/dev/null

# Depois dropar o usuário
dropuser -h "$DB_HOST" -p "$DB_PORT" -U postgres --if-exists "$DB_USER" 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Usuário removido com sucesso${NC}"
else
    echo -e "${YELLOW}⚠ Não foi possível remover o usuário (pode já não existir ou estar em uso)${NC}"
    echo -e "${YELLOW}  Tentando remover com força bruta...${NC}"
    
    # Forçar remoção como último recurso
    psql -h "$DB_HOST" -p "$DB_PORT" -U postgres -d postgres -c "
        REVOKE ALL PRIVILEGES ON DATABASE \"$DB_NAME\" FROM \"$DB_USER\";
        REVOKE ALL PRIVILEGES ON SCHEMA public FROM \"$DB_USER\";
        DROP USER IF EXISTS \"$DB_USER\";
    " 2>/dev/null
fi

# Limpar variável de ambiente da senha
unset PGPASSWORD

echo
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Processo concluído!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo
echo -e "${YELLOW}Resumo:${NC}"
echo "  • Banco '$DB_NAME': removido"
echo "  • Usuário '$DB_USER': removido"
echo
echo -e "${RED}Nota: Todos os dados foram permanentemente deletados.${NC}"