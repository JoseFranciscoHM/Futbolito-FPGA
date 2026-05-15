# Futbolito FPGA ⚽🎮

¡Bienvenido al proyecto **Futbolito FPGA**! Este es un juego de fútbol estilo "futbolito" (foosball) desarrollado íntegramente en VHDL para ser ejecutado en una placa de desarrollo FPGA (diseñado principalmente para la **Terasic DE2-115**).

## 📝 Descripción

El proyecto implementa la lógica de un juego de futbolito con salida de video VGA y sistema de audio dual. Los jugadores controlan porteros y defensas mediante botones físicos en la placa, compitiendo por anotar goles en la portería contraria.

### Características Principales:
- **Gráficos VGA**: Resolución de 640x480 o 800x600 con sprites animados para el balón y los jugadores.
- **Lógica de Juego Realista**: Rebotes, detección de colisiones 360° y sistema de puntuación.
- **Audio Dual**:
    - **Música de Fondo**: Generada internamente ("Pulo da Gaita").
    - **Efectos de Sonido (SFX)**: Reproducción de efectos de gol mediante el Codec de audio de la placa y control de un módulo externo **DFPlayer Mini** vía UART.
- **Interfaz de Usuario**: Marcador en pantalla con renderizado de caracteres mediante ROM.

## 🛠️ Requisitos de Hardware

- **FPGA**: Terasic DE2-115 (Cyclone IV).
- **Monitor**: Conexión VGA.
- **Audio**: Altavoces conectados al puerto Line Out o un módulo DFPlayer Mini conectado a los pines UART.
- **Controles**: Botones `KEY0`, `KEY1`, `KEY2`, `KEY3` para el movimiento de los jugadores.

## 📂 Estructura del Proyecto

- `VGA_BALL_TOP.vhd`: Entidad principal que conecta todos los módulos (Video, Audio, Lógica).
- `BALL.VHD`: Lógica de movimiento del balón, colisiones y control de jugadores.
- `vga_sync.vhd`: Generador de sincronía para la señal de video VGA.
- `Audio.vhd` / `i2c.vhd`: Controladores para el Codec de Audio WM8731.
- `dfplayer_ctrl.vhd`: Controlador UART para el módulo de audio externo.
- `TCGROM.MIF`: Archivo de inicialización de memoria para los caracteres del marcador.
- `scripts/`: Diversos scripts en Python para convertir imágenes a formatos compatibles con VHDL (`img_to_vhdl.py`, etc.).

## 🚀 Cómo Ejecutarlo

1. Abre el archivo de proyecto `.qpf` en **Altera Quartus II**.
2. Realiza el *Analysis & Synthesis*.
3. Asegúrate de que las asignaciones de pines coincidan con tu placa (ver `VGA_BALL.qsf`).
4. Compila el proyecto para generar el archivo `.sof`.
5. Carga el archivo `.sof` a tu placa DE2-115 mediante el *Programmer*.

## ✒️ Créditos

Proyecto desarrollado como parte de un trabajo final de sistemas digitales.
