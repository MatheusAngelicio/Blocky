# Blocky

Jogo casual 3D de empilhamento de blocos, criado com Flutter e Flutter Scene.

## Requisitos

- Flutter 3.47 estável ou mais recente;
- Dart 3.10 estável ou mais recente.

Após atualizar o SDK, execute `flutter pub get` para resolver o Flutter Scene
0.23.x.

## Estrutura

- `lib/app`: composição da aplicação Flutter;
- `lib/design_system`: componentes visuais compartilhados;
- `lib/game`: configurações e, futuramente, regras da partida;
- `lib/scene`: renderização 3D com Flutter Scene;
- `lib/ui`: telas e HUD feitos com widgets Flutter.

## Executar

Modo normal, com os temas desbloqueados pelo jogador:

```bash
fvm flutter run
```

Modo de desenvolvimento, com todos os temas disponíveis apenas durante aquela
execução:

```bash
fvm flutter run --dart-define=UNLOCK_ALL_THEMES=true
```

O modo de desenvolvimento não altera o saldo nem os temas desbloqueados salvos
no dispositivo.
