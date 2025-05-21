# MTH410E – RISC-V Architecture and Processor Design

## SuperScalar RISC-V Processor

Write a SystemVerilog code of pipelined/2-way superscalar pipelined RISC-V processor. The designed micro-architecture should include all the instructions in RV32I (It is in the [riscv-spec](https://github.com/riscv/riscv-isa-manual/releases/download/riscv-isa-release-bb8b912-2025-03-21/riscv-unprivileged.pdf)). 

The processor should work as in-order and multi-issue. It should resolve the all data control hazards either by stalling or full bypassing/scoreboard (+20 bonus points).
There is no need for FENCE, FENCE.TSO, PAUSE, ECALL, EBREAK instruction implementation. Additional to the RV32I, [CTZ](https://riscv-software-src.github.io/riscv-unified-db/manual/html/isa/isa_20240411/insts/ctz.html), [CLZ](https://riscv-software-src.github.io/riscv-unified-db/manual/html/isa/isa_20240411/insts/clz.html), and [CPOP](https://riscv-software-src.github.io/riscv-unified-db/manual/html/isa/isa_20240411/insts/cpop.html) must be implemented too.

The datapath of the processor should be as follows;
Datapath A (1 cycle): ALU operations (RV32 except memory operations)
Datapath B (1 cycle): MEM + ALU operations (RV32I)

**Note: This homework is same with the previous one. The only difference is being multi-cycle and pipelined architecture.**

The top file of the processor should be as follows;

```
module core_model
  import riscv_pkg::*;
(
    parameter DMemInitFile  = “dmem.mem”,     // data memory initialization file
    parameter IMemInitFile  = “imem.mem”,     // instruction memory initialization file
    parameter TableFile     = "table.log",    // processor state and used for verification/grading
    parameter IssueWidth    = 2               // 
)   (
    input  logic             clk_i,                       // system clock
    input  logic             rstn_i,                      // system reset
    input  logic  [XLEN-1:0] addr_i,                      // memory adddres input for reading
    output logic  [XLEN-1:0] data_o,                      // memory data output for reading
    output logic             update_o    [IssueWidth],    // retire signal
    output logic  [XLEN-1:0] pc_o        [IssueWidth],    // retired program counter
    output logic  [XLEN-1:0] instr_o     [IssueWidth],    // retired instruction
    output logic  [     4:0] reg_addr_o  [IssueWidth],    // retired register address
    output logic  [XLEN-1:0] reg_data_o  [IssueWidth],    // retired register data
    output logic  [XLEN-1:0] mem_addr_o  [IssueWidth],    // retired memory address
    output logic  [XLEN-1:0] mem_data_o  [IssueWidth],    // retired memory data
    output logic             mem_wrt_o   [IssueWidth]     // retired memory write enable signal
);
  // module body
  // use other modules according to the need.
  // pc_o[0] should always be the first instruction pc while retiring two instruction. 
  // pc_o[1] can only be valid when 2 instruction retired.

endmodule
```

The data and instruction memories of the processor should be initialized by DMemInitFile and  IMemInitFile respectively (i.e., use $readmemh in the initial block of the memories). Use TableFile to print the instruction states on the table.

All the addresses should be based on `0x8000_0000` you can use offset to get for example `0x8000` space after `0x8000_0000`. In other words, you address space for both IMEM and DMEM is from `0x8000_0000` to `0x8000_FFFF` (if you require more space for your implementation you can increase the ending address).

Some resources:
- [RISC-V: An Overview of the Instruction Set Architecture](https://web.cecs.pdx.edu/~harry/riscv/RISCV-Summary.pdf)
- [RISC-V Specification](https://github.com/riscv/riscv-isa-manual/releases/download/riscv-isa-release-bb8b912-2025-03-21/riscv-privileged.pdf)
- [Ripes](https://github.com/mortbopet/Ripes) a visual computer architecture simulator and assembly code editor.


Tasks:

1. Complete your RTL in SystemVerilog.
2. Clean all lint problems.
3. Run the example in the test folder.
4. Find other test and check (there will be other test cases to check).
5. Create a PC table for each cycle. state "flush" and "stall" states. Example is below("..." means the table continues). When there is a stall, labeling datapath either A or B as stall is not important. In other words, pc can be logged in any datapath when there is one stall in that stage. 

<style>
    .heatMap {
        width: 70%;
        text-align: center;
    }
    .heatMap th {
        background: grey;
        word-wrap: break-word;
        text-align: center;
    }
    .heatMap tr:nth-child(1) { background: blue; }
    .heatMap tr:nth-child(2) { background: blue; }
    .heatMap tr:nth-child(3) { background: green; }
    .heatMap tr:nth-child(4) { background: green; }
    .heatMap tr:nth-child(5) { background: blue; }
    .heatMap tr:nth-child(6) { background: blue; }
    .heatMap tr:nth-child(7) { background: green; }
    .heatMap tr:nth-child(8) { background: green; }
    .heatMap tr:nth-child(9) { background: blue; }
    .heatMap tr:nth-child(10) { background: blue; }
    .heatMap tr:nth-child(11) { background: green; }
    .heatMap tr:nth-child(12) { background: green; }
    .heatMap tr:nth-child(13) { background: blue; }
    .heatMap tr:nth-child(14) { background: blue; }
    .heatMap tr:nth-child(15) { background: green; }
    .heatMap tr:nth-child(16) { background: green; }
    .heatMap tr:nth-child(17) { background: blue; }
    .heatMap tr:nth-child(18) { background: blue; }
    .heatMap tr:nth-child(19) { background: green; }
    .heatMap tr:nth-child(20) { background: green; }
    .heatMap tr:nth-child(21) { background: blue; }
    .heatMap tr:nth-child(22) { background: blue; }
    .heatMap tr:nth-child(23) { background: green; }
    .heatMap tr:nth-child(24) { background: green; }
    .heatMap tr:nth-child(25) { background: blue; }
    .heatMap tr:nth-child(26) { background: blue; }
    .heatMap tr:nth-child(27) { background: green; }
    .heatMap tr:nth-child(28) { background: green; }
    .heatMap tr:nth-child(29) { background: blue; }
    .heatMap tr:nth-child(30) { background: blue; }
    .heatMap tr:nth-child(31) { background: green; }
    .heatMap tr:nth-child(32) { background: green; }
    .heatMap tr:nth-child(33) { background: blue; }
    .heatMap tr:nth-child(34) { background: blue; }
    .heatMap tr:nth-child(35) { background: green; }
    .heatMap tr:nth-child(36) { background: green; }
    .heatMap tr:nth-child(37) { background: blue; }
    .heatMap tr:nth-child(38) { background: blue; }
    .heatMap tr:nth-child(39) { background: green; }
    .heatMap tr:nth-child(40) { background: green; }
    .heatMap tr:nth-child(41) { background: blue; }
    .heatMap tr:nth-child(42) { background: blue; }
    .heatMap tr:nth-child(43) { background: green; }
    .heatMap tr:nth-child(44) { background: green; }
    .heatMap tr:nth-child(45) { background: blue; }
    .heatMap tr:nth-child(46) { background: blue; }
    .heatMap tr:nth-child(47) { background: green; }
    .heatMap tr:nth-child(48) { background: green; }
    .heatMap tr:nth-child(49) { background: blue; }
</style>

<div class="heatMap">

|     | F          | D          | I          | E          | M          | WB         |
|--   |--          |--          |--          |--          |--          |--          |
| 1A  | 0x80000000 |  -         |  -         | -          | -          | -          |
| 1B  | 0x80000004 |  -         |  -         | -          | -          | -          |
| 2A  | 0x80000008 | 0x80000000 |  -         | -          | -          | -          |
| 2B  | 0x8000000c | 0x80000004 |  -         | -          | -          | -          |
| 3A  | 0x80000008 | stall      | 0x80000000 | -          | -          | -          |
| 3B  | 0x8000000c | 0x80000004 | stall      | -          | -          | -          |
| 4A  | 0x80000010 | 0x80000008 | stall      | 0x80000000 | -          | -          |
| 4B  | 0x80000014 | 0x8000000c | 0x80000004 | stall      | -          | -          |
| 5A  | 0x80000018 | 0x80000010 | 0x80000008 | stall      | 0x80000000 | -          |
| 5B  | 0x8000001c | 0x80000014 | 0x8000000c | 0x80000004 | stall      | -          |
| 6A  | 0x80000020 | 0x80000018 | 0x80000010 | 0x80000008 | stall      | 0x80000000 |
| 6B  | 0x80000024 | 0x8000001c | 0x80000014 | 0x8000000c | 0x80000004 | stall      |
| 7A  | 0x80000020 | stall      | 0x80000018 | 0x80000010 | 0x80000008 | stall      |
| 7B  | 0x80000024 | 0x8000001c | stall      | 0x80000014 | 0x8000000c | 0x80000004 |
| 8A  | 0x80000028 | 0x80000020 | stall      | 0x80000018 | 0x80000010 | 0x80000008 |
| 8B  | 0x8000002c | 0x80000024 | 0x8000001c | stall      | 0x80000014 | 0x8000000c |
| 9A  | 0x8000002c | flush      | flush      | flush      | 0x80000018 | 0x80000010 |
| 9B  | 0x80000030 | flush      | flush      | flush      | stall      | 0x80000014 |
| 10A | 0x80000034 | 0x8000002c | flush      | flush      | flush      | 0x80000018 |
| 10B | 0x80000038 | 0x80000030 | flush      | flush      | flush      | stall      |
| 11A | 0x80000034 | stall      | 0x8000002c | flush      | flush      | flush      |
| 11B | 0x80000038 | 0x80000030 | stall      | flush      | flush      | flush      |
| 12A | 0x8000003c | 0x80000034 | stall      | 0x8000002c | flush      | flush      |
| 12B | 0x80000040 | 0x80000038 | 0x80000030 | stall      | flush      | flush      |
| 13A | ...        | ...        | ...        | ...        | ...        | ...        |
| 13B | ...        | ...        | ...        | ...        | ...        | ...        |

</div>

```
# Example assmebly code for table above
_0x80000000:    add x1,x2,x1
_0x80000004:    add x1,x2,x4
_0x80000008:    add x1,x2,x8
_0x8000000c:    add x1,x2,x12
_0x80000010:    add x1,x2,x16
_0x80000014:    add x1,x2,x20
_0x80000018:    beq x1,x2, label2
_0x8000001c:    nop
_0x80000020:    nop
_0x80000024:    nop
_0x80000028:    nop
label2:
_0x8000002c:    xor x1,x2,x1
_0x80000030:    xor x1,x2,x2
_0x80000034:    xor x1,x2,x3
_0x80000038:    xor x1,x2,x4
_0x8000003c:    xor x1,x2,x5
_0x80000040:    xor x1,x2,x6
```

---
# 📘 Homework Submission and Objection Rulebook
## 🎯 Purpose

To ensure fairness, standardization, and traceability in homework grading, the following rules must be followed. Assignments that do not comply with this rulebook will not be graded.
## 📤 Rulebook for Submission
1. Vivado files are NOT accepted.
2. All homework must be submitted via the assigned GitHub repository. No other platforms or file systems will be checked.
3. Grading is performed step-by-step using the provided Makefile. Your code must produce visible output and pass relevant steps.
4. Each step in the Makefile corresponds to specific grading components.
5. If your code does not complete a step in the Makefile, it will receive no marks for that step.
6. Dmem.mem must be empty at submission.
7. Dmem.mem and Imem.mem files must be located in the ./ directory, alongside the Makefile.
8. Do not modify the Makefile under any circumstances.
9. Submissions that follow the required system allow instructors to focus more on feedback. Remember: as an engineer, your system must work in different environments.
---
## ❗ Rulebook for Objections

1. Improper or spam-like emails (e.g. "Hocam çalışıyor", "Hocam bir daha bakın") will result in a 5-point penalty per email.
2. If you make false claims about instructions or grading criteria, and it's proven that you lied, your objection will be invalid and your grade will not be changed.
3. Objections must include a screen recording where:
    - The zip file from Ninova is extracted.
    - Commands are run from the root of the provided GitHub repo, using the original Makefile.
    - Linter and build steps are shown running successfully.
    - The video must be uploaded to YouTube and the link sent via email.
    - The length of the video cannot be longer than 2 minutes.
4. Any manipulation or deviation from the GitHub system will be considered copying.
5. Only objections that are proven with a video will be evaluated.

---
## 🧠 Some Reminders

- Please use the parameters from the top-level module declaration to initialize memories and write to log files.
- Please check the results in the log files produced by the provided tests. If your design works correctly, they should match the expected output.
- Please ensure that your design compiles and runs using the agreed-upon tools.
- Please verify that your design works with the provided testbench without any modifications.
- Your design must use all input signals, drive all specified output signals, and generate all required log files correctly.
- Be mindful of the address range defined in the assignment. Any violation may lead to malfunction or point deduction.
