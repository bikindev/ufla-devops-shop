# Analise de access.log -- Patricia Souza Couto (@bikindev)
**Linhas analisadas:** 516866
## 1. Volume e falha
‘‘‘bash
awk '$9 ~ /^4/ {print}' dados/access.log | wc -l && awk '$9 ~ /^5/ {print}' dados/access.log | wc -l
‘‘‘
6162
11749
‘‘‘
**Leitura:** O log possui 516866 requisicoes no total. 6162 falharam com 4xx e 11749 falharam com 5xx, o que representam 1,19% e 2,27% do total de requisicoes, respectivamente.

## 2. Os 10 IPs mais frequentes
'''bash
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -10
'''
88400 203.0.113.47
   1788 192.0.2.245
   1772 192.0.2.171
   1771 192.0.2.81
   1771 192.0.2.225
   1771 192.0.2.16
   1767 192.0.2.138
   1762 192.0.2.222
   1757 192.0.2.45
   1753 192.0.2.166
'''
   
'''bash
awk '{print $1 " " $6 " " $7}' access.log | sort | uniq -c | sort -rn | head -10
'''
    22224 203.0.113.47 "GET /api/busca?q=mochila
    22161 203.0.113.47 "GET /api/busca?q=tenis
    22090 203.0.113.47 "GET /api/busca?q=camiseta
    21925 203.0.113.47 "GET /api/busca?q=fone
    324 192.0.2.235 "GET /
    322 192.0.2.150 "GET /
    316 192.0.2.99 "GET /
    316 192.0.2.173 "GET /
    313 192.0.2.57 "GET /
    313 192.0.2.166 "GET /
'''

'''bash
grep '^203.0.113.47' access.log | awk '{print $4}' | cut -d: -f2 | uniq -c
'''
    30940 22
    57460 23
'''

**Leitura:** O IP mais frequente, responsavel por mais de 88 mil requsicoes, foi o 203.0.113.47. O segundo comando verifica quais foram as requisicoes mais realizadas pelos IPs, novamente destacando o IP mencionado. Suas requisicoes foram consultas por busca de produtos (como mochila, tenis, camiseta e fone) em quantidade massiva. E o terceiro comando evidencia os horarios em que as requisicoes foram realizadas, na janela de 2 horas (entre 22h e 00h). Tudo isso evidencia que o cliente ficou em um laco infinito na busca a partir das 22h.

## 3. Endpoint com mais 500
'''bash
awk '$9 == 500 {print $7}' access.log | sort | uniq -c | sort -rn | head -5
'''
   3620 /api/relatorio/gerar
    228 /
    167 /api/produtos
    160 /produtos
    150 /produtos/detalhe
'''

'''bash
awk '$7 == "/api/relatorio/gerar" {print $9}' access.log | sort | uniq -c | sort -rn
'''
   6780 200
   3620 500
'''

**Leitura:** o endpoint que mais quebra com o erro 500 eh /api/relatorio/gerar, com 3620 registros do erro. Com o segundo pipeline, podemos perceber que suas chamadas retornaram apenas dois status: 200 ou 500 e que ele quebra em 34,81% das vezes em que eh chamado.

## 4. Hora do pico
'''bash
awk '{print $4}' access.log | cut -d: -f2 | uniq -c
'''
   3262 00
   1967 01
   1810 02
   1471 03
   1498 04
   1844 05
   3904 06
   9759 07
  19519 08
  27621 09
  30869 10
  32526 11
  31895 12
  29952 13
  31225 14
  32529 15
  30886 16
  28575 17
  25996 18
  22807 19
  18860 20
  15577 21
  43979 22
  68535 23
'''

**Leitura:** A hora do dia com maior pico de requisicoes foi no periodo apos as 23h.

## 5. Caminhos sensíveis
'''bash
grep -E "admin|.evn|.git|wp-login|phpmyadmin" access.log | awk '{print "IP: " $1 ", end: " $7 ", status: " $9}' | sort | uniq -c
'''
    173 IP: 198.51.100.23, end: /admin/login, status: 404
    151 IP: 198.51.100.23, end: /admin, status: 404
    183 IP: 198.51.100.23, end: /.git/config, status: 404
    162 IP: 198.51.100.23, end: /phpmyadmin/index.php, status: 404
    171 IP: 198.51.100.23, end: /wp-login.php, status: 404
    209 IP: 198.51.100.9, end: /admin/login, status: 404
    162 IP: 198.51.100.9, end: /admin, status: 404
    173 IP: 198.51.100.9, end: /.git/config, status: 404
    156 IP: 198.51.100.9, end: /phpmyadmin/index.php, status: 404
    197 IP: 198.51.100.9, end: /wp-login.php, status: 404
'''

'''bash
grep -E "admin|.evn|.git|wp-login|phpmyadmin" access.log | awk '{print "IP: " $1 ", end: " $7 ", status: " $9}' | wc -l
'''
1737
'''
**Leitura:** Houve 1737 tentativas de acessar caminhos sensiveis, vindo especificamente de  IPs diferentes: 198.51.100.23 e 198.51.100.9. As tentativas foram mal sucedidas, pois o sistema negou-as com status 404.

## Conclusao: minha primeira acao como operador de plantao
A minha primeira acao seria de mitigacao: bloquear o IP ofensor 203.0.113.47 para interromper o tráfego abusivo de mais de 84 mil requisições dentro de 2 horas. Poderia fazer isso diretamente no Nginx com o comando "deny 203.0.113.47".
Em seguida, eu iria trabalhar no bloqueio preventivo de IPs de scan malicioso. Os IPs 198.51.100.23 e 198.51.100.9 realizaram 1737 varreduras através de caminhos sensíveis que, embora estejam recebendo o erro 404, devem ser bloqueados no firewall para economizar ciclos do worker.
Depois, não necessariamente no plantão, poderia avaliar a implementação de um rate limiting no Nginx para proteger endpoints caros (como busca) contra loops infinitos e investigar porque o endpoint /api/relatorio/gerar está apresentando taxa de falha de 34,81% em erro 500.

