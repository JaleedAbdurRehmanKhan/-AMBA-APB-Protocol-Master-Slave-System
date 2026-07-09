# AMBA APB Protocol Master-Slave System

This repository contains a full Verilog implementation of an AMBA Advanced Peripheral Bus (APB) Master-Slave communication system. It is designed to demonstrate advanced protocol features including back-to-back transfers, parametric wait-state injection, and slave stalling mechanisms.

## System Architecture

The project consists of three main components:
1. **APB Master (`apb_master.v`)**: A 3-state Finite State Machine (IDLE -> SETUP -> ACCESS) that conforms strictly to the AMBA APB specification. It handles front-end requests and translates them into APB bus transactions.
2. **APB Slave (`apb_slave.v`)**: A 32-entry, 32-bit word-addressed register bank (`mem[0:255]`). It features combinational reads and sequential writes, along with parametric wait-state logic (configurable default of 3 cycles) to simulate slow peripherals.
3. **Testbench (`tb_apb.v`)**: A self-checking testbench that validates write and read transactions, ensuring data integrity (e.g., writing `0xDEADBEEF` and verifying the readback).

## Key Features

- **Back-to-Back Transfers**: Master can seamlessly execute continuous read/write cycles without returning to IDLE.
- **Parametric Wait States**: Slave can intentionally stall the bus by holding `pready` low for a configurable number of clock cycles.
- **Protocol Compliance**: Strictly follows setup and access phase timing as per the ARM AMBA specification.

## Simulation
The design was simulated and verified using Vivado.
