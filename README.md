# FPS Log Parser

Sistema de análise de logs de partidas de FPS (First Person Shooter) desenvolvido em Ruby on Rails.

## Melhorias Futuras (TODO LIST)

- Extrair lógica de cada tipo de event handlers para micro cases separados, criando uma espécie de factory que decide para qual event handler (case) mandar
- ~~Tratar caso de borda em que um mesmo arquivo é enviado novamente, contando kills para uma partida já iniciada e terminada~~
- Ver a possibilidade de melhorar as queries de estatísticas
- Adicionar paginação nas views das tabelas
- Criar mais componentes reutilizáveis para o sistema

## Bonus implementados
- Descobrir arma preferia do vencedor
- Jogadores que vencerem uma partida sem morrer devem ganhar um award
- Ranking Global

## Bonus futuros a serem implementados
- Identificar maior sequência de frag
- Jogadores que matarem 5 vezes em 1 minuto devem ganhar um award
- Permitir que os jogadores sejam classificados em times, Lógica de teamkill penalizando pontos.

## Funcionalidades

- **Upload de Logs**: Interface web para upload de arquivos de log
- **Parser Automático**: Processamento automático de logs com identificação de:
  - Início e fim de partidas
  - Jogadores participantes
  - Kills e mortes
  - Armas utilizadas
- **Estatísticas de Partidas**: Visualização detalhada de cada partida com rankings
- **Rankings Globais**: Leaderboard com estatísticas acumuladas de todos os jogadores
- **Validação de Partidas**: Partidas com mais de 20 jogadores são marcadas como invãlidas
- **Interface Responsiva**: Design feito com biblioteca de componentes DaisyUI 

## Tecnologias

- Ruby 3.3.0
- Rails 8.0.2
- PostgreSQL
- RSpec (testes)
- Tailwind CSS + DaisyUI
- dry-monads (gerenciamento de resultados)
- ViewComponent

## Instalação

1. Clone o repositório:
```bash
git clone https://github.com/seu-usuario/FpsLogParser.git
cd FpsLogParser
```

2. Instale as dependências:
```bash
bundle install
```

3. Configure o banco de dados:
```bash
rails db:create
rails db:migrate
```

4. Execute os testes:
```bash
bundle exec rspec
```

5. Inicie o servidor:
```bash
rails server
```

6. Acesse http://localhost:3000

## Formato do Log

O parser espera logs no seguinte formato:

```
23/04/2019 15:34:22 - New match 11348965 has started
23/04/2019 15:36:04 - Roman killed Nick using M16
23/04/2019 15:36:33 - <WORLD> killed Nick by DROWN
23/04/2019 15:39:22 - Match 11348965 has ended
```

## Estrutura do Projeto

### Models
- **Match**: Representa uma partida com início, fim e duração
- **Player**: Jogador com estatísticas acumuladas
- **Kill**: Evento de kill com killer, vítima e arma
- **MatchPlayer**: Associação entre jogador e partida com estatísticas individuais do jogador na partida

### Services
- **LogParser**: Processa arquivos de log e popula o banco
- **MatchStatistics**: Calcula estatíssticas de uma partida específica
- **GlobalStatistics**: Gera rankings e estatísticas globais

### Controllers
- **UploadsController**: Gerencia upload e processamento de logs
- **MatchesController**: Exibe lista e detalhes de partidas
- **RankingsController**: Mostra rankings globais

## Regras de Negócio

- Partidas com mais de 20 jogadores são marcadas como inválidas
- Partidas inválidas não contam para estatísticas globais
- Mortes causadas pelo mundo (<WORLD>) contam como morte mas nãoo como kill
- K/D ratio � calculado como kills/deaths (ou kills se deaths = 0)
