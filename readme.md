# ComputeComponents for Barotrauma
Adds compute components for building and programming computers in Barotrauma. Requires LUA mod.

## ROM Component
### Inputs
- clock_in: The clock signal
- address_in: The address being read
### Outputs
- data_out: The data read from the ROM

## CPU Component
### Inputs:
- clock_in: The clock signal
- data_in: Data going into the CPU from memory/peripherals
- interrupt_in: Not yet implemented
### Outputs
- address_out: The address to be read from
- data_out: The data going to memory/peripherals
### Instruction Set
- SET \[register\] \[immediate\]: Loads the immediate value into the register
- ADDI \[register1\] \[register1\] \[immediate\]: Adds the immediate value to register 2 and stores the result in register 1
- OUT \[register1\] \[register2\]: Sends data to the address in register 1 with the value of register 2
- JMP \[address\]: Unconditional jump to address in memory