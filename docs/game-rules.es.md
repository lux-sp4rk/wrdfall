# wordfall: Reglas del Juego

wordfall es un juego de palabras estratégico donde la formación de palabras se encuentra con Tetris. El modo de juego principal es **Loom Drop** — un puzzle de letras que caen al estilo Tetris donde deslizas para formar palabras en una cuadrícula de 5x5.

## Cómo Jugar

1. **Las letras caen** una a la vez en la cuadrícula de 5x5 desde columnas aleatorias.
2. **Desliza sobre fichas adyacentes** (horizontal, vertical o diagonal) para deletrear una palabra de 3+ letras.
3. **Las letras coincidentes se eliminan** del tablero y la gravedad arrastra las fichas restantes hacia abajo.
4. **Gana puntos** para gastar en potenciadores que te ayudan a gestionar el tablero.
5. **Limpia todo el tablero** para ganar, o **déjalo llenarse** para perder.

## La Cuadrícula

- **Tamaño:** 5 columnas x 5 filas (25 fichas en total)
- **Estado inicial:** Las 3 filas inferiores están pre-llenadas con letras, incluyendo varias palabras semilla plantadas para darte un inicio jugable.
- **Selección:** Arrastra sobre las fichas en cualquiera de las 8 direcciones (arriba, abajo, izquierda, derecha y las 4 diagonales). Cada ficha en tu camino debe ser adyacente a la anterior.

## Puntuación

La puntuación se calcula por palabra como:

> **Puntuación = Suma de Letras x Multiplicador de Longitud x Multiplicador de Combo**

### Valores de las Letras

Cada letra tiene un valor de puntos basado en su rareza estilo Scrabble:

| Puntos | Letras en Español |
|--------|-------------------|
| 1 | A, E, I, L, N, O, R, S, T, U |
| 2 | D, G |
| 3 | B, C, M, P |
| 4 | F, H, V, W, Y |
| 5 | K, Q |
| 8 | J, X |
| 10 | Z |

### Multiplicador de Longitud

Las palabras más largas ganan exponencialmente más. El multiplicador se aplica a la suma total de letras:

| Longitud de Palabra | Multiplicador |
|---------------------|---------------|
| 3 letras | 1x |
| 4 letras | 2x |
| 5 letras | 4x |
| 6+ letras | 8x |

### Racha de Combos

Palabras consecutivas de 4+ letras construyen una racha de combo que multiplica tu puntuación aún más:

- Solo las palabras de **4 o más letras** construyen y mantienen la racha.
- Una **palabra de 3 letras reinicia** la racha a cero.
- Cada paso de la racha añade **+0.5x** al multiplicador de combo (comenzando desde 1.0x).
- El multiplicador de combo **tiene un límite de 3.0x**.

| Racha | Multiplicador de Combo |
|-------|------------------------|
| 0 | 1.0x |
| 1 | 1.5x |
| 2 | 2.0x |
| 3 | 2.5x |
| 4+ | 3.0x (límite) |

### Ejemplos de Puntuación

| Palabra | Suma de Letras | Mult. de Longitud | Combo (racha 0) | Total |
|---------|----------------|-------------------|-----------------|-------|
| GATO | 5 | 1x | 1.0x | 5 |
| ESTAR | 4 | 2x | 1.0x | 8 |
| LIMPIO | 14 | 4x | 1.0x | 56 |
| JAZZ | 29 | 2x | 1.0x | 58 |

Con un combo de racha 2 (2.0x):

| Palabra | Suma de Letras | Mult. de Longitud | Combo | Total |
|---------|----------------|-------------------|-------|-------|
| ESTAR | 4 | 2x | 2.0x | 16 |
| LIMPIO | 14 | 4x | 2.0x | 112 |

## Aumento de Velocidad de Caída

El ritmo de las letras que caen aumenta con el tiempo, creando presión creciente:

- Cada **5 letras que caen**, el intervalo de caída disminuye en **0.5 segundos**.
- El intervalo nunca baja de **2 segundos** (el piso de velocidad).
- Obtener una **palabra de 5+ letras reinicia** la velocidad de caída a su ritmo original y reinicia el contador de caídas.

Esto crea una tensión central: jugar seguro con palabras cortas y el juego acelera sin cesar, o invertir en palabras más largas para mantener el ritmo manejable.

| Caídas | Intervalo Normal | Intervalo Difícil |
|--------|------------------|-------------------|
| 0-4 | 8.0s | 4.0s |
| 5-9 | 7.5s | 3.5s |
| 10-14 | 7.0s | 3.0s |
| 15-19 | 6.5s | 2.5s |
| 20-24 | 6.0s | 2.0s |
| 25+ | 5.5s | 2.0s (piso) |

## Potenciadores

Los potenciadores cuestan puntos ganados al limpiar palabras. Después de usar cualquier potenciador, se aplica gravedad para asentar el tablero.

### Sacudida

Redistribuye aleatoriamente todas las letras del tablero en nuevas posiciones.

| | Normal | Difícil |
|---|--------|---------|
| **Costo** | 3 pts | 8 pts |

### Intercambio

Elige dos fichas en el tablero e intercambia sus posiciones. Entra en modo de selección — selecciona la primera ficha, luego selecciona cualquier segunda ficha con una letra.

| | Normal | Difícil |
|---|--------|---------|
| **Costo** | 2 pts | 5 pts |

Presiona **ESC** o toca el botón Intercambio de nuevo para cancelar el modo de selección.

### Sacar Más

Saca hasta 5 letras nuevas en columnas abiertas aleatorias (la fila superior debe tener espacio en esas columnas).

| | Normal | Difícil |
|---|--------|---------|
| **Costo** | 5 pts | 10 pts |

## Modos de Dificultad

### Normal

- **Intervalo de caída:** 8 segundos (base)
- **Proporción de vocales:** Aumentada en 15% — aparecen más vocales, facilitando la formación de palabras
- **Palabras de rescate:** Habilitadas — cuando no existen palabras válidas en el tablero, el juego sesga las letras que caen para construir una palabra jugable
- Costos de potenciadores más bajos

### Difícil

- **Intervalo de caída:** 4 segundos (50% más rápido)
- **Proporción de vocales:** Reducida en 25% — menos vocales, tableros con más consonantes
- **Palabras de rescate:** Deshabilitadas — no hay red de seguridad
- Costos de potenciadores más altos

## Condiciones de Victoria y Derrota

- **Victoria:** Limpia cada letra de la cuadrícula de 5x5 (todas las 25 celdas vacías).
- **Derrota:** Las 25 celdas están ocupadas — no hay espacio para la siguiente caída.

El juego **no termina** cuando no existen palabras válidas en el tablero. Los jugadores deben usar potenciadores (Sacudida, Intercambio, Sacar Más) para crear nuevas oportunidades de palabras, o esperar caídas de letras favorables.

## Distribución de Letras

Las letras no son puramente aleatorias. El sistema de caídas usa tres estrategias para mantener los tableros jugables:

1. **Bolsa ponderada** — Las letras se extraen de una distribución ponderada estilo Scrabble (E y A aparecen mucho más frecuentemente que Q y Z).
2. **Conciencia de bigramas** — 50% del tiempo, la letra que cae se elige basándose en qué letra está debajo, favoreciendo pares de letras comunes (QU, EN, ER, IN, etc.).
3. **Equilibrio de vocales** — Si la proporción de vocales del tablero cae por debajo del objetivo, la siguiente caída se sesga hacia las vocales.

## Idiomas

wordfall soporta inglés y español, intercambiables en la pantalla de Configuración.

- **Inglés:** Diccionario SOWPODS (~270k palabras)
- **Español:** Diccionario FISE 2017 (~639k palabras), incluye la letra &#xD1;
