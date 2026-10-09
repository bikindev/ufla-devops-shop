# Atividade 4 -- Patricia Souza Couto

## 1. Tamanho da imagem Antes vs Depois
Comando usado para verificar o valor de cada versao:
```bash
docker images | grep ufla-shop
```
ufla-shop:1.0             02e25134670a        453MB          115MB        
ufla-shop:1.1             546cf21e1d8b        157MB         36.6MB        
ufla-shop:1.2             ffb89b9f4120        126MB         29.4MB   

## 2. Otimizacao do tamanho da imagem
O que mudou e quanto economizou: a versao 1.0 ja usava a imagem base python:3.12-alpine e o arquivo .dockerignore foi criado corretamente, porém essa versao mantinha as ferramentas de compilacao utilizadas, somando um valor de 453MB de tamanho em disco. Na versão 1.1, foi utilizada a abordagem Multi-Stage Build para iniciar uma imagem limpa sem essas ferramentas, mas ainda assim, a imagem ficou com um tamanho de 157MB. Para tentar reduzir mais, a versao 1.2 faz uma limpeza dentro do container, após o build, para remover quaisquer arquivos desnecessarios que ficaram em /opt/venv/ (copiados para o estágio 2), como executaveis de empacotamento (pip, wheel, setuptools) e subdiretorios de teste. A imagem final ficou com 126MB.

## 3. Verificação
### 3.1. Usuario Nao-Root (id -u != 0)
```bash
docker run --rm ufla-shop:1.0 id -u
```
100

### 3.2. Status da saude (Healthcheck)
```bash

docker inspect --format '{{.State.Health.Status}}' loja
```
healthy

## 4. Tempo de encerramento (docker stop < 2s)
```bash
time docker stop loja
docker rm loja
```
loja

real	0m0.460s
user	0m0.018s
sys	0m0.016s
loja

## 5. Por que o HEALTHCHECK consulta `/health` e não `/ready`?
O endpoint `/health` avalia se o processo da aplicação em si esta vivo e apto a processar requisicoes HTTP (liveness), operando independentemente da presenca de servicos externos. Ja o endpoint `/ready` valida a prontidao do sistema completo (readiness), verificando conexoes ativas com o banco de dados PostgreSQL e cache Redis, os quais nao fazem parte deste container isolado nesta atividade.

