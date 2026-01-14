# 🎮 Diferenças de Gameplay - Original vs Seu App

## Mecânica Original (blocked.jeffsieu.com)

### Sistema de Controle Único
O jogo original tem uma mecânica **muito específica**:

1. **Apenas UM bloco é controlável por vez** (marcado com um círculo ⭕)
2. **Controle por setas** (teclado) ou swipe (mobile)
3. **Transferência de controle**: Quando o bloco controlado **colide** com outro bloco, o controle é **transferido** para o bloco atingido
4. **Regra importante**: O controle só é transferido se colidir com **exatamente 1 bloco** (não funciona se colidir com 2+ blocos simultaneamente)

### Exemplo de Gameplay:
```
Nível 1-2:
*******
*M.xxxe    M = bloco principal (controlável)
*..xxx*    x = blocos secundários
*..xxx*    e = saída
*.....*
*.....*
*******

Passos:
1. M move → direita (colide com xxx)
2. Controle transferido para xxx
3. xxx move ↓ para baixo
4. Controle volta para M (ao colidir novamente)
5. M move → para a saída
```

---

## Seu App (Atual)

### Sistema de Drag & Drop
- ❌ **Qualquer bloco** pode ser arrastado a qualquer momento
- ❌ Não há conceito de "controle único"
- ❌ Não há transferência de controle
- ❌ Mecânica completamente diferente

---

## O Que Precisa Mudar

### 1. Sistema de Controle

#### Adicionar:
```dart
class GameController {
  Block? controlledBlock;  // Apenas 1 bloco controlável
  
  void transferControl(Block targetBlock) {
    // Só transfere se colidir com exatamente 1 bloco
    controlledBlock = targetBlock;
  }
}
```

### 2. Input do Usuário

#### Trocar de Drag para Setas:
```dart
// REMOVER: GestureDetector com onPanUpdate
// ADICIONAR: RawKeyboardListener ou botões direcionais

Widget build(BuildContext context) {
  return RawKeyboardListener(
    focusNode: FocusNode(),
    onKey: (RawKeyEvent event) {
      if (event is RawKeyDownEvent) {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.arrowUp:
            moveControlledBlock(Direction.up);
            break;
          case LogicalKeyboardKey.arrowDown:
            moveControlledBlock(Direction.down);
            break;
          // etc...
        }
      }
    },
    child: gameBoard,
  );
}
```

### 3. Lógica de Movimento

#### Movimento com Colisão:
```dart
void moveControlledBlock(Direction direction) {
  if (controlledBlock == null) return;
  
  // 1. Mover bloco na direção
  // 2. Detectar colisão
  // 3. Se colidiu com EXATAMENTE 1 bloco:
  //    - Transferir controle para esse bloco
  // 4. Se colidiu com parede ou múltiplos blocos:
  //    - Parar movimento
  //    - Não transferir controle
}
```

### 4. Indicador Visual

#### Mostrar qual bloco está controlado:
```dart
// No BlockWidget
Container(
  decoration: BoxDecoration(
    border: Border.all(
      color: isControlled 
        ? gameColors.activeBlockBorder  // Verde neon
        : gameColors.blockBorder,
      width: isControlled ? 3 : 2,
    ),
  ),
  child: isControlled && block.isPrimary
    ? Icon(Icons.circle_outlined)  // Círculo no bloco principal
    : null,
)
```

---

## Diferenças de Layout

### Tamanho dos Blocos

**Original:**
- Blocos têm **espaçamento mínimo** entre si (1-2px)
- Grid bem **compacto**
- Bordas **finas** (1-2px)

**Seu App (provável):**
- Blocos com **mais espaçamento**
- Bordas **mais grossas**
- Grid **menos compacto**

### Correção:
```dart
// No BlockWidget
Container(
  margin: EdgeInsets.all(1), // Espaçamento mínimo
  decoration: BoxDecoration(
    border: Border.all(
      width: 2, // Borda fina
    ),
  ),
)
```

---

## Prioridade de Mudanças

### 🔴 Crítico (Quebra o jogo):
1. ✅ Implementar sistema de controle único
2. ✅ Trocar drag por setas/botões
3. ✅ Implementar transferência de controle

### 🟡 Importante (Afeta experiência):
4. ✅ Ajustar espaçamento dos blocos
5. ✅ Adicionar indicador visual de controle
6. ✅ Ajustar tamanho das bordas

### 🟢 Polimento (Visual):
7. ✅ Animações suaves
8. ✅ Sons de colisão
9. ✅ Feedback tátil

---

## Próximos Passos

Quer que eu:

**A)** Implemente a mecânica de controle único (sistema de setas + transferência)?

**B)** Apenas ajuste o layout/espaçamento dos blocos?

**C)** Crie um documento detalhado de como implementar tudo?

**D)** Mantenha o drag mas tente aproximar mais do visual original?

Me diga qual caminho prefere! 🎮
