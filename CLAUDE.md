# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ESPHome-based firmware for the **Waveshare ESP32-S3-Touch-LCD-7** (model 27078) — a 7" 800×480 IPS capacitive touchscreen dev board. The goal is to build a Home Assistant dashboard (and potentially a voice satellite) using ESPHome + LVGL.

## Hardware Summary

- **SoC:** ESP32-S3-WROOM-1-N16R8 (dual-core LX7 @ 240 MHz, 16 MB Flash, 8 MB PSRAM octal)
- **Display:** 7" IPS 800×480, ST7262 controller, RGB parallel interface
- **Touch:** GT911, 5-point capacitive, I2C (SDA: GPIO8, SCL: GPIO9, IRQ: GPIO4)
- **IO Expander:** CH422G (I2C) — controls backlight (EXIO2), touch reset (EXIO1), SD CS (EXIO4), CAN/USB mux (EXIO5)
- **Connectivity:** WiFi 2.4 GHz, BLE 5 (onboard antenna — known weak signal due to backlight shield)
- **Interfaces:** USB-C (CH343 UART + native USB), SD card (SPI), RS485, CAN/TWAI (TJA1051), I2C header, ADC terminal
- **Power:** 5V USB-C (~450 mA), optional 3.7V LiPo with onboard charging (CS8501)
- **No onboard audio** — voice satellite requires external I2S mic (INMP441) + amp (MAX98357A); free GPIO pins are very limited since RGB display uses most of them

## Key Technical Constraints

- PSRAM must run in octal mode at **80 MHz** (`psram: speed: 80MHz`) — 120 MHz from the base package causes bootloop on this board
- The inytar base package defaults to `flash_size: 8MB` — this board has 16MB, override with `esp32: flash_size: 16MB`
- GPIO19/20 are shared between CAN and native USB — mode selected via CH422G EXIO5
- The RGB display consumes nearly all GPIO pins; available pins for expansion are limited to I2C, RS485 (GPIO15/16), and CAN (GPIO19/20)
- WiFi signal is attenuated by the backlight shield — position the board with care
- OTA updates are unreliable while LVGL is running at 120 Hz — pause LVGL before OTA
- I2C addresses 0x20–0x27, 0x30–0x3F, 0x5D are occupied by onboard peripherals

## ESPHome Development

### Base Package

Use the community ESPHome package as a starting point:
https://github.com/inytar/waveshare-esp32-s3-touch-lcd-7-esphome

This package handles display init, touch, backlight, and antiburn. Requires ESPHome >= 2025.4.2.

### Environment Setup

```bash
make install   # create .venv (Python 3.13) and install ESPHome — Python 3.14 is incompatible
make sh        # enter venv shell (alias: make shell)
make gen-key   # generate base64 API encryption key
```

### Build & Flash

```bash
esphome run <config>.yaml          # compile, upload, and monitor
esphome compile <config>.yaml      # compile only
esphome upload <config>.yaml       # upload only (OTA or USB)
esphome logs <config>.yaml         # serial/network log monitor
esphome config <config>.yaml       # validate YAML config
```

### Config Architecture

- `waveshare-7-package.yaml` — reusable package (hardware overrides, UI, sensors) — no secrets, safe for public repos
- `waveshare-7.yaml` — device config (name, WiFi, API key) — includes the package, references `secrets.yaml`
- `secrets.yaml` — gitignored, credentials only; see `secrets.yaml.example` for keys

### Remote Package Loading

The `github://` shorthand is unreliable. Use the extended `url` + `files` syntax on the homelab ESPHome dashboard:

```yaml
packages:
  device:
    url: https://github.com/msurma/ESP32-S3
    files: [waveshare-7-package.yaml]
    ref: main
```

Remote packages cannot use `!secret` — use `substitutions` with defaults instead.

### Key Display Pins (for ESPHome rpi_dpi_rgb platform)

```
DE: GPIO5, HSYNC: GPIO46, VSYNC: GPIO3, PCLK: GPIO7
R: GPIO1,2,42,41,40  G: GPIO39,0,45,48,47,21  B: GPIO14,38,18,17,10
```

## Home Assistant Devices

Full device list with entity IDs is in `DEVICES.md`. Use it to reference HA entities in ESPHome configs and LVGL UI.

## Integration Context

- The owner runs **Home Assistant** with **Voice PE** on custom ESPHome firmware
- Primary goal: HA touchscreen dashboard via LVGL
- Secondary goal: voice satellite integration (pending audio hardware)
- External 5W Waveshare speakers are available for audio output

## Iterative Workflow

1. User requests a change
2. Analyze scope, plan approach, ask clarifying questions if needed
3. Implement the change
4. Compile and upload: `esphome compile waveshare-7.yaml && esphome upload --device 192.168.1.228 waveshare-7.yaml`
5. User tests on device — if OK, commit and loop back to step 1; if not, fix and repeat from step 3

## Commit Message Rules

- Always use a **single line** — never multi-line commit messages
- Prefix with `fix:`, `feature:`, or `chore:`
- Example: `fix: correct GT911 touch interrupt pin assignment`
- **Never** include `Co-Authored-By` or any trailer lines
