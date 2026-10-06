# Autopsia: AWS S3 (us-east1) (28/02/2017)

**Autor:** Patricia Souza Couto (@bikindev)
**Fonte primaria:** https://aws.amazon.com/message/41926/
**Data de acesso:** 30/08/2026

## 1. O que aconteceu

Durante uma manutencao rotineira, um operador digitou um comando com parametro errado e desligou muito mais servidores do que pretendia. Essa remocao derrubou os subsistemas centrais de catalogo e alocacao de arquivos da Amazon S3, paralisando operaçoes de leitura, escrita e servicos dependentes em toda a regiao. 
Inicio: 28 de fevereiro de 2017, 09:37 PST - execucao do comando incorreto. 
Deteccao imediata as 09:37 PST, devido a queda em cascata das APIs e inicio do processo de reinicializacao.
Restauracao: parciais as 12:26 PST e 13:18 PST e conclusao total as 13:54 PST.

## 2. Qual das Tres Vias falhou

Falhou a Segunda Via - Feedback Rapido e Continuo. A Segunda Via estabelece que o sistema deve fornecer respostas seguras, conter o raio de explosao (blast radius) de qualquer alteracao e possuir mecanismos de seguranca que impecam falhas humanas de se propagarem de forma catastrofica antes de atingirem a producao. No incidente, o sistema aceitou um comando destrutivo sem qualquer validacao ou safeguard. O relatorio expoe esse problema de feedback ao relatar: "the tool used allowed too much capacity to be removed too quickly. We have modified this tool to remove capacity more slowly and added safeguards to prevent capacity from being removed when it will take any subsystem below its minimum required capacity level".

## 3. Quais metricas DORA teriam denunciado antes

<quais das quatro, e o mecanismo de deteccao>

- Tempo medio de restauracao
Embora o S3 seja concebido para tolerar falhas pontuais de capacidade, os subsistemas criticos de indice e alocacao nao passavam por uma reinicializacao completa em regioes de grande porte ha anos. Como o volume de dados cresceu exponencialmente sem testes frequentes de recuperacao, a validacao de integridade dos metadados demorou mais de quatro horas. Essa incapacidade de restaurar o servico rapidamente em um cenario de desastre amplo ja representava um risco latente.

- Taxa de falha em mudancas:
A operacao de remocao de capacidade era tratada como uma rotina operacional manual, dependente exclusivamente de intervencao humana e execuvso via playbook. A inexistencia de automatizacoes de validacao de parametros e testes previos aumentava expressivamente a probabilidade de que qualquer manutencao rotineira gerasse indisponibilidade severa.

## 4. Qual pratica do semestre teria evitado -- e em que semana

A pratica que teria evitado o incidente eh o gerenciamento declarativo de infraestrutura (IaC - Semana 14 / Modelo Declarativo - Semana 10).
Em uma abordagem declarativa com IaC ou orquestradores (Kubernetes/Terraform), engenheiros nao executam comandos imperativos diretos no terminal para desativar nos em tempo real. A alteracao de capacidade passaria por um arquivo de configuracao versionado, no qual o estado desejado seria validado contra politicas automatizadas (policy-as-code), barrando reducoes abaixo do limite operacional de seguranca (floor capacity). E o provisionamento/desprovisionamento seria executado de forma gradual, impedindo a destruicao em lote instantanea provocada pelo erro de digitacao.

## 5. A cultura do relatorio: generativa ou patologica?

A cultura demonstrada no relatorio eh generativa (orientada a desempenho e aprendizado) pela tipologia de Westrum. Em uma organizacao patologica, o foco recairia sobre a culpabilizacao do operador que cometeu o erro de digitacao (blaming), punindo o individuo e mantendo as falhas sistemicas ocultas. No post-mortem da AWS, o erro humano eh tratado como sintoma de um processo fragil: a responsabilidade eh atribuida aa ferramenta que permitia uma remocao descontrolada e a falta de particionamento em celulas menores.

trecho que sustenta essa cultura: "While removal of capacity is a key operational practice, in this instance, the tool used allowed too much capacity to be removed too quickly. We have modified this tool to remove capacity more slowly and added safeguards to prevent capacity from being removed when it will take any subsystem below its minimum required capacity level."


