# CS223 VGA Game of Life Project – Spring 2025

This repository contains two different implementations of **Conway’s Game of Life** using VGA output on the Basys3 FPGA board, developed for the CS223 Term Project at Bilkent University.

## 🧩 Project Overview

The goal of this project is to create a fully functional digital circuit system using SystemVerilog to simulate **Conway’s Game of Life**, a classic cellular automaton, with VGA video output. The implementation is divided into stages and progressively builds up to a real-time, interactive grid-based simulation.

## 📺 Project Stages (per specification)

- **Stage 1** – VGA controller with a colored checkerboard pattern and scrollable image using directional buttons.
- **Stage 2** – Interactive canvas with:
  - White background,
  - Cursor movement via directional buttons,
  - Drawing using center button (BTNC),
  - Canvas reset using a switch.
- **Stage 3** – Implementation of Conway’s Game of Life rules:
  - 80×60 grid with 8×8 cells (RAM-based version),
  - Simulation controlled by left (start/stop) and right (clear/reset) switches,
  - Game rules applied to the grid and rendered in real time.

## 🧠 Implementations

### 1. `ram_based_8x8/` – **Optimized Version**
> **Grid Size:** 80×60 (8×8 pixel squares)  
> **Memory:** Explicit RAM (4800x1 bits)  
> **Performance:** Fastest synthesis, suitable for large grid updates  
> **Highlight:** Uses two separate RAMs for current and next generation, enabling pipelined updates. Ideal for hardware-accurate modeling.

**Key Features:**
- Uses dual RAM buffers (`current_grid`, `next_grid`)
- Fully implemented FSM for:
  - Initialization and clear,
  - Cursor-controlled cell toggle,
  - Game rule application,
  - Frame-wise state transition (copy-back with wait states)
- Proper VGA timing and grid rendering
- Shows cursor only when paused
- Grid lines rendered separately

**Use Case:** If you care about synthesis speed and simulation accuracy with a moderate square size.

---

### 2. `array_based_16x16/` – **Simplified Direct Array Version**
> **Grid Size:** 40×30 (16×16 pixel squares)  
> **Memory:** 2D logic array (`cells[x][y]`)  
> **Performance:** Slower for synthesis, but easier to understand  
> **Highlight:** Combines all logic and simulation directly into one large always block.

**Key Features:**
- Uses simple 2D arrays (`cells` and `next_cells`)
- Updates entire grid with simulation tick
- Ideal for quick tests and demos
- Cursor and simulation work similarly to RAM version, but logic is flattened

**Use Case:** If you want straightforward simulation with less module complexity.

---

## 🕹️ Controls

| Control      | Function                            |
|--------------|-------------------------------------|
| `BTNU`       | Move cursor up                      |
| `BTND`       | Move cursor down                    |
| `BTNL`       | Move cursor left                    |
| `BTNR`       | Move cursor right                   |
| `BTNC`       | Toggle cell state under cursor      |
| `Right Switch (V17)` | Clear grid and stop simulation |
| `Left Switch (V16)`  | Start/Stop simulation toggle  |

---

## 🔧 Requirements

- **Basys3 FPGA Board**
- **Vivado 2023.1 or later**
- Monitor with VGA input

---

## 📘 References

1. Conway’s Game of Life — [Wikipedia](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life)  
2. VGA Signal Timing — [TinyVGA.com](http://www.tinyvga.com/vga-timing/640x480@60Hz)  
3. VGA Format and Specs — [Valcarce](http://javiervalcarce.eu/html/vga-signal-format-timming-specs-en.html)

---

## 🎓 Project Information

- **Course:** CS223 – Digital Design  
- **University:** Bilkent University   
- **Term:** Spring 2025  
- **Student:** Ege Ural  

---

## 🧪 Bonus Tips

- Synthesize the 8×8 RAM version first for faster iteration.
- Use the lab monitors for better VGA compatibility.
- Adjust the simulation tick rate (clock divider) if movement feels too fast/slow.

---


