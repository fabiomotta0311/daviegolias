# Davi e Golias: O Duelo no Vale de Elá ⚔️

Jogo 2D de ação e combate contra chefe (*boss fight*) baseado na passagem bíblica de 1 Samuel 17. Desenvolvido em **Godot 4** com **GDScript**, com toda a arte e efeitos visuais gerados proceduralmente via código (sem dependência de assets gráficos externos).

---

## 📖 História & Ambientação
No Vale de Elá, o exército de Israel e os filisteus estão acampados em montes opostos. Golias de Gate, o campeão filisteu de armadura de escamas de bronze, desafia o povo. O jovem pastor Davi, munido apenas de seu cajado, seu alforje com pedras lisas do ribeiro e sua funda, avança no combate em nome do Senhor dos Exércitos.

---

## 📜 Passagens Bíblicas no Jogo (1 Samuel 17)

Todas as mecânicas, diálogos e elementos visuais do jogo foram modelados diretamente a partir dos versículos de **1 Samuel 17**:

| Versículo | Texto Bíblico | Elemento correspondente no Jogo |
| :--- | :--- | :--- |
| **1 Sm 17:1-3** | *"E os filisteus estavam num monte de um lado, e os israelitas no outro monte do outro lado; e o vale estava entre eles."* | **Cenário:** O Vale de Elá com os acampamentos de tendas e bandeiras nos morros opostos, soldados assistindo e oliveiras. |
| **1 Sm 17:4-7** | *"Tinha na cabeça um capacete de bronze, e vestia uma couraça de escamas [...] grevas de bronze [...] um dardo de bronze [...] e a haste da sua lança era como o eixo do tecelão..."* | **Visual e Ataques de Golias:** Golias modelado com capacete de bronze e penacho, couraça de escamas, grevas nas canelas, dardo nas costas e ataque de arremesso de lança. |
| **1 Sm 17:18** | *"Leva também estes dez queijos ao capitão de mil; e verás como passam teus irmãos e tomarás o seu penhor."* | **Item de Cura:** Um queijo cai do céu durante o combate e recupera 1 coração de vida para Davi. |
| **1 Sm 17:37** | *"O Senhor me livrou das garras do leão, e das do urso; ele me livrará da mão deste filisteu."* | **Falas de Davi:** Davi brada em combate recordando a proteção divina no pastoreio. |
| **1 Sm 17:40** | *"E tomou o seu cajado na mão, e escolheu para si cinco pedras lisas do ribeiro, e as pôs no alforje de pastor [...] e lançou mão da sua funda..."* | **Armamento de Davi:** Túnica de pastor, funda giratória com força variável e alforje com **exatamente 5 pedras**, recarregadas no ribeiro. |
| **1 Sm 17:43-44** | *"Disse o filisteu a Davi: Sou eu algum cão, para tu vires a mim com paus? E o filisteu amaldiçoou a Davi pelos seus deuses [...] Vem a mim, e darei a tua carne às aves do céu..."* | **Provocações de Golias:** Balões de fala no início da luta e ao entrar em Modo Fúria (< 40% de vida). |
| **1 Sm 17:45** | *"Tu vens a mim com espada, e com lança, e com escudo; porém eu venho a ti em nome do Senhor dos Exércitos, o Deus dos exércitos de Israel..."* | **Versículo-Tema:** Exibido na tela de título e falado por Davi na abertura do duelo. |
| **1 Sm 17:47** | *"Pois do Senhor é a batalha, e ele vos entregará nas nossas mãos."* | **Grito de Batalha:** Davi exclama *"A batalha é do Senhor!"* durante os acertos e ao vencer. |
| **1 Sm 17:49** | *"E Davi [...] com a funda lha atirou, e feriu o filisteu na testa; e a pedra se lhe cravou na testa, e caiu sobre o seu rosto em terra."* | **Ponto Fraco:** O corpo de Golias tem armadura (dano baixo), mas acertar **a testa** causa dano crítico (35 pts), tremor de tela e atordoamento (*stun*). |
| **1 Sm 17:50** | *"Assim Davi prevaleceu contra o filisteu com uma funda e uma pedra, e feriu o filisteu, e o matou..."* | **Tela de Vitória:** Citação em destaque quando o gigante é derrotado. |

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
