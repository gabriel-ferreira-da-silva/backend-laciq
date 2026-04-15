# banco de dados postgresql

criando banco de dados

```
sudo -u postgres psql
```

no terminal postgre crie banco

```
CREATE DATABASE laciq_database;
```
se conecta com o banco

```
\c laciq_database
```

crie o usuario 

```

```
CREATE USER laciq_owner WITH PASSWORD 'schrodingerAndPauliAndHeisenbergAndMarcela';
GRANT ALL ON SCHEMA public TO laciq_owner;
ALTER SCHEMA public OWNER TO laciq_owner;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO laciq_owner;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO laciq_owner;



```

dar permissões

```
GRANT ALL PRIVILEGES ON DATABASE laciq_database TO laciq_owner;
```

