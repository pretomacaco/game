# guia para Executar o Jogo no Termux

Este guia fornece instruções sobre como atualizar os repositórios, instalar o Git, clonar o repositório e iniciar o jogo usando o Love2D no Termux.

## Passo 1: Atualizar Repositórios

Antes de instalar novos pacotes, é uma boa prática atualizar os repositórios do Termux. Execute o seguinte comando:

```
pkg update && pkg upgrade

Passo 2: Instalar o Git

Para clonar repositórios do GitHub, você precisa instalar o Git. Execute o comando abaixo:

pkg install git

Passo 3: Clonar o Repositório

Clone o repositório do jogo usando o comando git clone:

bash

git clone https://github.com/exfurr-bash/game

Passo 4: Entrar na Pasta do Repositório

Navegue para a pasta do repositório clonado:

cd game

Passo 5: Instalar o Love2D

Para rodar o jogo, você precisa instalar o Love2D. Execute o comando abaixo para instalar:

pkg install love

Passo 6: Iniciar o Jogo

Agora, você pode iniciar o jogo com o Love2D. Execute o seguinte comando dentro da pasta do repositório:

love .
ˋˋˋ
Isso abrirá o jogo usando o Love2
