# Davi e Golias: O Duelo no Vale de Elá ⚔️

Jogo 2D de ação e combate contra chefe (*boss fight*) baseado na passagem bíblica de 1 Samuel 17. Desenvolvido em **Godot 4** com **GDScript**, com toda a arte e efeitos visuais gerados proceduralmente via código (sem dependência de assets gráficos externos).

---

## 📖 História & Ambientação
No Vale de Elá, o exército de Israel e os filisteus estão acampados em montes opostos. Golias de Gate, o campeão filisteu de armadura de escamas de bronze, desafia o povo. O jovem pastor Davi, munido apenas de seu cajado, seu alforje com pedras lisas do ribeiro e sua funda, avança no combate em nome do Senhor dos Exércitos.

---

## ✨ Funcionalidades

- **Davi (Jogador):**
  - Movimentação fluida com física personalizada (aceleração, *coyote time*, salto variável).
  - Esquiva/rolamento com invulnerabilidade temporária (no solo e no ar).
  - Sistema de funda: carregamento dinâmico de força com linha de trajetória parabólica e indicador em anel.
  - Alforje de 5 pedras lisas com recarga no ribeiro e coleta de pedras perdidas no solo.
  - Item especial de cura: queijo que cai do céu (1 Samuel 17:18).

- **Golias (Chefe):**
  - Múltiplas caixas de colisão: corpo (armadura com dano reduzido) e cabeça/testa (ponto fraco crítico + atordoamento/stun).
  - Golpes telegrafados: soco descendente com punho preso no chão, pisão com onda de choque rasteira (dupla onda em modo fúria) e arremesso de lança à distância.
  - Modo Fúria (*Enrage*) ao atingir menos de 40% de vida.

- **Cenário & Efeitos:**
  - Vale de Elá com acampamentos, tendas, soldados de ambos os exércitos que comemoram e reagem, oliveiras e ribeiro animado.
  - *Freeze-frame* no acerto crítico, tremor de tela dinâmico (*screen shake*), partículas de poeira e faíscas, câmera lenta no golpe final.
  - Efeitos sonoros procedurais sintetizados em 16-bits e tambores de guerra.

- **Acessibilidade e Dificuldades:**
  - 3 modos de dificuldade: Fácil (5 vidas, mira assistida e testa brilhando), Normal e Difícil.
  - Avisos visuais e dicas na tela para facilitar o aprendizado de crianças.
  - Menu de pausa (`P` ou `Esc`), tela de vitória com estatísticas e tela de derrota com dicas.

---

## 🎮 Controles

| Ação | Teclado / Mouse |
| :--- | :--- |
| **Mover** | `A` / `D` ou Setas |
| **Pular** | `W`, `Espaço` ou Seta Cima |
| **Esquivar / Rolar** | `Shift`, `C` ou `Botão Direito do Mouse` |
| **Mirar e Atirar** | Segure `Botão Esquerdo do Mouse` ou `F` e solte |
| **Recolher pedras** | `E` (junto ao ribeiro ou sobre pedras caídas) |
| **Pausar** | `P` ou `Esc` |
| **Reiniciar** | `R` |
| **Mutar Áudio** | `M` |

---

## 🚀 Como Executar

### Pré-requisitos
- [Godot Engine 4.x](https://godotengine.org/) (Standard 64-bit).

### Executando o Jogo
1. Clone o repositório:
   ```bash
   git clone https://github.com/fabiomotta0311/daviegolias.git
   ```
2. Abra o executável do Godot 4 e importe o arquivo `project.godot`.
3. Ou, no Windows, basta rodar o executável do Godot apontando para a pasta:
   ```cmd
   godot.exe --path .
   ```
