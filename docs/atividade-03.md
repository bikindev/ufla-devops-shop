Atividade 3 -- Patricia Souza Couto

## (a) Como rodar o deploy.sh numa maquina limpa
Para provisionar a aplicacao em um ambiente Linux limpo (Debian/Ubuntu) com systemd, siga os passos abaixo:

### 1. Estrutura de Arquivos da Entrega
Os artefatos desenvolvidos nesta atividade estao versionados na arvore do repositorio:
* `systemd/ufla-shop.service`: Unit do servico principal da API FastAPI (usuario nao-root `ufla-shop`, `Restart=on-failure`, `EnvironmentFile`).
* `systemd/ufla-shop-backup.service`: Unit do tipo `oneshot` responsáael por disparar o script de backup.
* `systemd/ufla-shop-backup.timer`: Timer agendado para executar o backup diariamente as 03:00 com `Persistent=true`.
* `scripts/backup.sh`: Script idempotente com `set -euo pipefail` que realiza `pg_dump` comprimido com `gzip`, registra log via `logger` e rotaciona mantendo apenas os 7 dumps mais recentes.
* `nginx/loja.conf`: Configuracao do proxy reverso com terminacao TLS (porta 443), redirecionamento permanente HTTP (porta 80 -> 443) e cabecalhos de encaminhamento (`X-Real-IP`, `X-Forwarded-*`).
* `scripts/deploy.sh`: Script mestre de automação idempotente.

---

### 2. Passo a Passo de Execucao em Ambiente Limpo

#### 1. Clonar o repositorio e acessar a branch da atividade
Clone o seu fork do projeto:
$ git clone [https://github.com/](https://github.com/)<SEU_USUARIO>/ufla-devops-shop.git
$ cd ufla-devops-shop

Alterne para a branch da atividade 3:
$ git switch atividade-03

#### 2. Inicializar o banco de dados e cache (Pré-requisitos da aplicação)
A API necessita de instâncias ativas do PostgreSQL e Redis para inicialização correta das rotas /health e /ready:

$ sudo apt-get update -y
$ sudo apt-get install -y postgresql redis-server
$ sudo systemctl enable --now postgresql redis-server
$ sudo -u postgres psql -c "CREATE USER loja WITH PASSWORD 'troque-esta-senha';"
$ sudo -u postgres psql -c "CREATE DATABASE loja OWNER loja;"

#### 3. Conceder permissão e executar o deploy automatizado
$ chmod +x scripts/deploy.sh scripts/backup.sh
$ sudo ./scripts/deploy.sh

## Evidencias:
### (b) - a saída de systemctl status ufla-shop depois do kill
$ systemctl status ufla-shop
● ufla-shop.service - UFLA DevOps Shop API
     Loaded: loaded (/etc/systemd/system/ufla-shop.service; enabled; preset: enabled)
     Active: active (running) since Tue 2026-10-06 15:00:57 -03; 7s ago
 Invocation: 3b68914cdcd247af903f34ce079c1990
   Main PID: 56824 (uvicorn)
      Tasks: 2 (limit: 8517)
     Memory: 50.2M (peak: 51.1M)
        CPU: 395ms

$ sudo kill -9 $(pgrep -f "uvicorn app:api")
$ systemctl status ufla-shop
● ufla-shop.service - UFLA DevOps Shop API
     Loaded: loaded (/etc/systemd/system/ufla-shop.service; enabled; preset: enabled)
     Active: active (running) since Tue 2026-10-06 15:01:35 -03; 12s ago
 Invocation: 099e2b7db09a42fe9450125053bf5358
   Main PID: 57071 (uvicorn)
      Tasks: 1 (limit: 8517)
     Memory: 48.5M (peak: 48.8M)
        CPU: 355ms

### (c) - validação do Nginx
$ curl -I http://localhost
HTTP/1.1 301 Moved Permanently
Server: nginx/1.28.3 (Ubuntu)
Date: Tue, 06 Oct 2026 18:05:09 GMT
Content-Type: text/html
Content-Length: 178
Connection: keep-alive
Location: https://localhost/

$ curl -kI https://localhost
HTTP/1.1 405 Method Not Allowed
Server: nginx/1.28.3 (Ubuntu)
Date: Tue, 06 Oct 2026 18:05:38 GMT
Content-Type: application/json
Content-Length: 31
Connection: keep-alive
allow: GET

$ curl -ki https://localhost -o /dev/null -D -
  % Total    % Received % Xferd  Average Speed  Time    Time    Time   Current
                                 Dload  Upload  Total   Spent   Left   Speed
  0      0   0      0   0      0      0      0                              0HTTP/1.1 200 OK
Server: nginx/1.28.3 (Ubuntu)
Date: Tue, 06 Oct 2026 18:10:18 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 1262
Connection: keep-alive
accept-ranges: bytes
last-modified: Tue, 06 Oct 2026 18:00:55 GMT
etag: "f9e390b1fcda77a6e6ffc430fda57f42"

100   1262 100   1262   0      0  49649      0                              0


### (d) - backup executado manualmente 3 vezes
$ sudo ls -la /var/backups/ufla-shop
total 20
drwx------ 2 root root 4096 Oct  6 14:17 .
drwxr-xr-x 3 root root 4096 Oct  6 14:16 ..
-rw-r--r-- 1 root root   20 Oct  6 14:16 loja-2026-10-06-141644.sql.gz
-rw-r--r-- 1 root root 1626 Oct  6 14:17 loja-2026-10-06-141706.sql.gz
-rw-r--r-- 1 root root 1625 Oct  6 14:17 loja-2026-10-06-141716.sql.gz

### Agendador ativado
$ systemctl list-timers ufla-shop-backup.timer
NEXT                        LEFT LAST PASSED UNIT                   ACTIVATES               
Wed 2026-10-07 03:00:00 -03  12h -         - ufla-shop-backup.timer ufla-shop-backup.service


### (e) - prova de idempotencia -> o comando sudo ./scripts/deploy.sh foi executado duas vezes seguidas e as linhas finais de cada saída foram as mesmas:

$ sudo ./scripts/deploy.sh
==> Ajustando permissões de diretório...
==> Gerando certificado TLS autoassinado...
==> Configurando Nginx...
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
==> Instalando units e timer do systemd...
Created symlink '/etc/systemd/system/multi-user.target.wants/ufla-shop.service' → '/etc/systemd/system/ufla-shop.service'.
Created symlink '/etc/systemd/system/timers.target.wants/ufla-shop-backup.timer' → '/etc/systemd/system/ufla-shop-backup.timer'.
==> Executando healthcheck em http://localhost:8000/ready...
Tentativa 1/10 falhou (Status: 000). Aguardando 1s...
Aplicação operacional e pronta (tentativa 2)!

$ sudo ./scripts/deploy.sh
==> Ajustando permissões de diretório...
==> Gerando certificado TLS autoassinado...
==> Configurando Nginx...
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
==> Instalando units e timer do systemd...
==> Executando healthcheck em http://localhost:8000/ready...
Tentativa 1/10 falhou (Status: 000). Aguardando 1s...
Aplicação operacional e pronta (tentativa 2)!
