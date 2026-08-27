# ⚡ Low-Power 8-Bit MAC Accelerator — RTL-to-GDSII ASIC Flow
### Fully Hardened, DRC/LVS-Clean Digital ASIC on SkyWater 130nm PDK

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PDK: SkyWater 130nm](https://img.shields.io/badge/PDK-SkyWater%20130nm%20(sky130hd)-orange.svg)](https://github.com/google/skywater-pdk)
[![EDA Flow: OpenROAD / Yosys](https://img.shields.io/badge/EDA-OpenROAD%20%7C%20Yosys%20%7C%20Magic%20%7C%20KLayout-brightgreen.svg)](https://theopenroadproject.org/)
[![Status: GDSII Signoff Clean](https://img.shields.io/badge/Physical%20Signoff-DRC%20%2F%20LVS%20%2F%20STA%20Clean-success.svg)]()

---

## 📌 Executive Summary

This repository contains the complete end-to-end ASIC implementation of an **8-bit Multiply-Accumulate (MAC) Unit** targeted for edge DSP and low-power AI/ML accelerator workloads. 

The physical design flow was taken strictly from synthesizable **SystemVerilog RTL to tapeout-ready GDSII** utilizing the open-source **SkyWater 130nm Standard Cell Library (`sky130_fd_sc_hd`)** through **OpenROAD Flow Scripts (ORFS)**, **Yosys**, and **Magic/KLayout**.

### 🏆 Key PPA & Signoff Highlights
| Parameter | Result | Signoff Corner / Notes |
| :--- | :--- | :--- |
| **Technology Node** | SkyWater 130nm (`sky130hd`) | High-density standard cell library |
| **Operating Frequency** | **100 MHz** ($T_{clk} = 10.0\,\text{ns}$) | Target met with **+2.40 ns positive slack** |
| **Total Power Dissipation** | **0.864 mW** ($8.64 \times 10^{-4}\,\text{W}$) | $V_{DD} = 1.80\,\text{V}$, Static + Dynamic |
| **Total Core Area** | **5,062 $\mu\text{m}^2$** | Active std cell area: $3,889.98\,\mu\text{m}^2$ |
| **Core Utilization** | **16.0%** | Optimized for zero routing congestion |
| **Worst-Case IR Drop** | **$7.36 \times 10^{-5}\,\text{V}$ ($0.00\%$)** | On $V_{DD}$ grid ($1.80\,\text{V}$ nominal) |
| **Standard Cell Count** | **431 logic cells** (4,420 total incl. tap/fill) | 33 Sequential (DFF), 331 Comb, 60 Buffers |
| **Physical Verification** | **Zero DRC Violations, Device-Clean LVS** | KLayout DRC + Magic Extraction Signoff |

---

## 📐 Architecture & Microarchitecture

The MAC core executes continuous vector dot-product computations:
$$\text{Accumulator} \leftarrow (\mathbf{A} \times \mathbf{B}) + \text{Accumulator}$$

                       +------------------------+
a[7:0] =============> | 8x8 Parallel Multiplier|
b[7:0] =============> | (16-bit Product) |
+-----------+------------+
|
v
+-----------+------------+
enable -------------> | |
start -------------> | 32-bit Carry-Save | <======== [ Feedback ]
rst_n -------------> | Accumulator | |
+-----------+------------+ |
| |
+======== [ 32-bit Register ]+
|
result[31:0] <=======================+
done <----------------------- Control FSM


### Microarchitectural Features
* **Operand Width**: Dual 8-bit signed/unsigned integer inputs.
* **Accumulator Depth**: 32-bit register to guarantee overflow-free processing across 65,536 accumulation cycles.
* **Low-Power Control**: Clock-gating ready, explicit handshake protocol (`start`, `enable`, `done`).
* **Clean Reset Strategy**: Active-low asynchronous reset with synchronized deassertion handling.

---

## 🔄 ASIC Execution Flow

```mermaid
graph TD
    A[SystemVerilog RTL: mac_core.sv] --> B[Functional Verification: Icarus Verilog + GTKWave]
    B --> C[RTL Lint & Synth: Yosys + Sky130 HD Liberty]
    C --> D[Synthesized Gate-Level Netlist: mac_core_synth.v]
    D --> E[SDC Timing Constraints: 100MHz Target]
    E --> F[Floorplanning & Power Grid IO Pin Placement]
    F --> G[Global & Detailed Standard Cell Placement]
    G --> H[Clock Tree Synthesis CTS: H-Tree Buffer Insertion]
    H --> I[Detailed Routing: Global FastRoute + Detailed TritonRoute]
    I --> J[Parasitic Extraction SPEF / RCX]
    J --> K[Signoff STA: OpenSTA Multi-Corner Timing]
    K --> L[Physical Verification: Magic DRC & LVS]
    L --> M[Final Mask-Ready GDSII: mac_core_final.gds]

    style A fill:#1e293b,stroke:#38bdf8,stroke-width:2px,color:#fff
    style D fill:#1e293b,stroke:#38bdf8,stroke-width:2px,color:#fff
    style M fill:#047857,stroke:#10b981,stroke-width:3px,color:#fff
🛠️ Physical Design & Implementation Details
1. Logic Synthesis (Yosys)
Synthesized to sky130_fd_sc_hd target cell library.
Total logic gate count: 431 physical gates ($3,889.98,\mu\text{m}^2$).
Sequential area distribution: $825.79,\mu\text{m}^2$ ($21.23%$).
0 lint warnings / 0 syntax violations on final netlist handoff.
2. Constraints Management (Constraints/constraint.sdc)
current_design mac_core
set clk_name    clk
set clk_period  10.0
set clk_io_pct  0.2

create_clock -name $clk_name -period $clk_period [get_ports clk]
set_false_path -from [get_ports rst_n]

set_input_delay  [expr $clk_period * $clk_io_pct] -clock $clk_name [get_ports {enable start a b}]
set_output_delay [expr $clk_period * $clk_io_pct] -clock $clk_name [get_ports {result done}]
3. Floorplanning & Power Distribution Network (PDN)
Die bounds: Automated standard cell core boundary at $5,062,\mu\text{m}^2$.
Power straps constructed on met4 and met5 with continuous vertical/horizontal met1 standard cell power rails.
Well-tap and decap insertion to prevent latch-up and manage localized supply rail bounces.
4. Clock Tree Synthesis (CTS) & Routing
Balanced clock buffer insertion: 6 dedicated sky130_fd_sc_hd__clkbuf_1 cells.
Max clock skew bounded within acceptable margins across PVT corners.
Nanometer detailed routing via global grid allocation and TritonRoute without DRC/antenna violations.
5. Static Timing Analysis (STA) & Power Integrity
Setup Slack: Clean positive slack (+2.40 ns) under 100 MHz clock rate.
Dynamic / Static Power: 0.864 mW static + dynamic dissipation.
IR Drop Analysis: Max calculated voltage drop on $V_{DD}$ is $73.6,\mu\text{V}$ (negligible, $0.00%$ supply degradation).
📊 Layout & Physical Signoff Visuals
1. Functional Waveform Verification	2. Full Physical Layout (GDSII)
![Waveform](Results/Images/gtk_verification_waveform.pdf) <br> Functional check in GTKWave	![Full Layout](Results/Images/final_all.webp) <br> Full chip layout view
3. Standard Cell Placement	4. Clock Tree Buffer Distribution
![Placement](Results/Images/final_placement.webp) <br> Placement density & macro boundary	![Clock Tree](Results/Images/final_clocks.webp) <br> CTS root-to-sink buffer distribution
5. Global & Detailed Routing	6. Full-Grid IR Drop Heatmap
![Routing](Results/Images/final_routing.webp) <br> Metal layer interconnect tracks	![IR Drop](Results/Images/final_ir_drop.webp) <br> Static & dynamic power rail drops
🗂️ Repository Directory Structure
Low-Power-MAC-Sky130--RTL-to-GDSII/
├── Constraints/
│   └── constraint.sdc              # SDC timing budgets (100MHz clock, I/O delays)
├── GDS/
│   └── mac_core_final.gds          # Final tapeout-ready GDSII stream
├── RTL/
│   └── mac_core.sv                 # Synthesizable SystemVerilog MAC RTL
├── TestBench/
│   ├── mac_core_tb.sv              # Self-checking functional testbench
│   └── mac_core.gtkw               # GTKWave signal configuration
├── Scripts/
│   └── synth.ys                    # Yosys synthesis automation script
├── Results/
│   ├── Images/                     # Layout, CTS, routing, and IR drop renders
│   ├── Reports/                    # Signoff STA, CTS, DRC, LVS, and area logs
│   │   ├── 4_cts_final.rpt
│   │   ├── 6_finish.rpt
│   │   ├── drc_report.txt          # Zero-violation DRC runset log
│   │   ├── lvs_summary.txt         # 431/431 device match verification
│   │   ├── final_report_summary.txt
│   │   ├── synth_check.txt
│   │   └── synth_stat.txt
│   └── Synthesis/
│       ├── mac_core_synth.v        # Synthesized gate-level netlist
│       └── synthesis_report.txt
└── README.md
⚙️ How to Reproduce
Prerequisites
Yosys (Logic Synthesis)
OpenROAD / OpenROAD-flow-scripts (ORFS)
KLayout / Magic (DRC/LVS Signoff)
Icarus Verilog & GTKWave (RTL Simulation)
SkyWater 130nm PDK (sky130hd)
1. Functional Simulation
iverilog -g2012 -o mac_sim TestBench/mac_core_tb.sv RTL/mac_core.sv
vvp mac_sim
gtkwave TestBench/mac_core.gtkw
2. Logic Synthesis
yosys -s Scripts/synth.ys
3. Physical Implementation (OpenROAD)
# Export PDK directory & launch physical flow
export PDK_ROOT=/path/to/skywater-pdk
openroad -exit flow.tcl
👨‍💻 Author
Yuvraj Mishra
Focus Areas: Digital VLSI Design | RTL-to-GDSII Physical Design | Static Timing Analysis (STA) | Low-Power SoC Architecture

---

### 💼 Bonus: How to showcase this on LinkedIn & Resume

#### 1. Resume Bullet Points (Copy & Paste under "Projects"):
> **Low-Power 8-Bit MAC Accelerator (SkyWater 130nm RTL-to-GDSII)**
> * Designed and verified a synthesizable 8-bit Multiply-Accumulate (MAC) accelerator in SystemVerilog for edge DSP workloads.
> * Implemented the full RTL-to-GDSII physical design flow using **Yosys, OpenROAD, and Sky130nm PDK**, executing logic synthesis, floorplanning, placement, CTS, and detailed routing.
> * Achieved **100 MHz timing closure with +2.40 ns positive slack**, consuming **0.864 mW total power** within a **5,062μm 
2
  core area**.
> * Performed physical signoff with **0 DRC errors**, verified 431/431 logic devices in LVS, and validated power integrity with <0.01% worst-case IR drop.

#### 2. LinkedIn Post Draft:
> 🚀 Excited to share my latest ASIC Physical Design project: **Low-Power 8-Bit MAC Accelerator — Complete RTL-to-GDSII Flow on SkyWater 130nm PDK**!
>
> 🔹 **Architecture**: Parameterized 8-bit MAC unit with a 32-bit overflow-free accumulator and active handshaking.
> 🔹 **Synthesis & Implementation**: Mapped to `sky130_fd_sc_hd` using Yosys & OpenROAD.
> 🔹 **PPA & Signoff Results**:
> • Target Frequency: **100 MHz** (Closed with **+2.40 ns setup slack**)
> • Total Power: **0.864 mW @ 1.8V**
> • Core Area: **5,062 µm²**
> • Signoff: **DRC-clean, LVS-verified (431 device match), and negligible IR-drop (7.36×10 
−5
  V)**
>
> 🔗 Check out the full repository, reports, and layout heatmaps here: [Link to your GitHub Repo]
>
> #VLSI #PhysicalDesign #ASIC #Semiconductor #OpenROAD #SkyWater130 #RTLtoGDSII #DigitalDesign 
