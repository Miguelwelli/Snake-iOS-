# Snake-iOS-

Jogo da cobrinha (Snake) nativo para iPhone, escrito em **Swift + SwiftUI** e pronto
para compilar com **[xtool](https://xtool.sh)**. Sem dependências externas, sem
serviços pagos e sem APIs externas.

## Visuais

- Fundo verde escuro, quase preto.
- Cobra verde neon.
- Comida vermelha.
- Grade discreta sobre o tabuleiro.
- Placar em destaque no topo da tela.
- Animações suaves de movimento, crescimento e game over.

## Jogabilidade

1. A cobra começa a se mover sozinha.
2. A direção é controlada deslizando o dedo na tela.
3. Também há quatro botões direcionais grandes.
4. Comer comida faz a cobra crescer e vale +10 pontos.
5. A comida aparece em posições aleatórias.
6. Bater na parede ou no próprio corpo encerra o jogo.
7. Há um botão "Jogar novamente".
8. A velocidade aumenta gradualmente à medida que a pontuação sobe.

Toque no tabuleiro para pausar/despausar.

## Requisitos técnicos

- SwiftUI.
- iOS 17 ou posterior.
- Swift Package Manager.
- `xtool.yml` com `bundleID: com.miguelwelli.snakeios`.
- Orientação retrato (portrait) no iPhone.
- Código organizado em dois arquivos, sem dependências desnecessárias.

## Arquivos

| Caminho | Conteúdo |
|---|---|
| `Package.swift` | Manifesto do SwiftPM (alvo `SnakeIOS`, iOS 17+). |
| `xtool.yml` | Configuração do xtool (`bundleID: com.miguelwelli.snakeios`). |
| `Sources/SnakeIOS/SnakeIOSApp.swift` | Ponto de entrada (`@main`) e bloqueio de orientação retrato. |
| `Sources/SnakeIOS/SnakeGameView.swift` | Modelo do jogo (@MainActor) e toda a interface SwiftUI. |
| `.gitignore` | Artefatos do SwiftPM, xcodebuild e saída do xtool. |
| `README.md` | Este arquivo. |

## Como compilar com o xtool

### Pré-requisitos

**Linux/WSL:** toolchain Swift 6.4, o binário do xtool e o SDK Darwin gerado pelo
`xtool setup` a partir de um `Xcode.xip` (baixado com um Apple ID em
developer.apple.com).

**macOS:** Xcode + `brew install xtool-org/tap/xtool`.

### Comandos (execute no diretório que contém o `Package.swift`)

```sh
# 1. Linux: uma única vez, faça login e gere/instale o SDK Darwin.
xtool setup

# 2. Compile, assine e instale no iPhone conectado por USB.
xtool dev

# 2b. Apenas gere o pacote do app.
xtool dev build            # xtool/SnakeIOS.app
xtool dev build --ipa      # xtool/SnakeIOS.ipa

# 3. Build otimizado (release).
xtool dev -c release

# 4. (macOS apenas) simulação.
xtool dev run --simulator
```

O app é assinado com o bundle ID `com.miguelwelli.snakeios`. Em iPhone real, o
xtool prefixa o ID ao assinar (ex.: `XTL-<equipe>.com.miguelwelli.snakeios`); basta
confiar no desenvolver em Ajustes > Geral > Gerenciamento de dispositivo e VPN.

### Sobre a compilação neste repositório

O Swift não está instalado neste ambiente de edição, portanto o projeto **não foi
compilado localmente**; foi revisado linha a linha contra o formato de projeto do
xtool (`Package.swift` de 6.0 com um único produto de biblioteca automática,
`xtool.yml` com `version: 1` e `bundleID`, ponto de entrada `@main` no alvo da
biblioteca). Compile e instale com o xtool em um Mac ou num Linux com o SDK Darwin.
