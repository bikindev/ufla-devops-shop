# Patricia Souza Couto

- **GitHub:** @bikindev
- **Curso e periodo:** Sistemas de Informacao, 10 periodo
- **Linguagem que voce domina melhor:** Python
- **Ja usou Linux no dia a dia?** sim
- **Ja usou Docker?** nunca
- **O que voce espera desta disciplina:** Como atuo na area de dados e ainda tenho uma base mais inicial em engenharia de software, espero compreender os fundamentos praticos de DevOps, automacao e conteinerizacao para ampliar minha visao tecnica. Quero adquirir uma base solida para comecar a pensar e aplicar praticas de CI/CD e esteiras automatizadas tambem no contexto de dados, algo que hoje ainda nao utilizo no meu dia a dia de trabalho.

## Diagnostico DORA do meu ultimo projeto

Pense no **ultimo projeto de software que voce entregou** — trabalho de
disciplina, projeto pessoal, estagio, TCC, o que for. Responda com honestidade.
Nao existe resposta errada aqui, e a nota **nao** depende de os numeros serem
bons.

- **Frequencia de implantacao:** quantas vezes aquele software foi para
  "producao" (entregue funcionando para alguem usar)?
  4

- **Lead time para mudancas:** quanto tempo passava, tipicamente, entre voce
  escrever um trecho de codigo e ele estar disponivel para o usuario?
  2 semanas

- **Tempo de restauracao:** quando algo quebrava na apresentacao ou em uso,
  quanto tempo levava para voltar a funcionar?
  5 dias

- **Taxa de falha em mudancas:** que proporcao das entregas quebrou algo que
  antes funcionava?
  50

### Qual metrica era a pior, e por que

A pior metrica foi o Tempo de restauracao (5 dias), agravada diretamente pela alta Taxa de falha em mudancas (50%). No OtakuLens, como a aplicacao foi estruturada em varios microsservicos com FastAPI, RAG, MCP e integracao com LLM, qualquer alteracao na comunicacao entre servicos, nos contratos de API ou na ingestao dos dados, quebrava o fluxo de ponta a ponta; sem pipelines automatizados de testes, monitoramento de dependencias ou ambientes conteinerizados reproduziveis, o diagnostico de falhas e a depuracao manual demandavam muito tempo de investigacao e retrabalho para restabelecer o sistema.

---

> Guarde este arquivo. Na **semana 15** voce vai reler o que escreveu hoje e
> refazer o mesmo diagnostico sobre a plataforma que tera construido. A
> diferenca entre os dois textos e, na pratica, o que voce aprendeu no semestre.


