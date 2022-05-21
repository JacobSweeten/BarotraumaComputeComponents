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
- write_enable_out: Sets whether or not the CPU is writing to or reading from memory (Not yet implemented)
### Instruction Set
- SET \[register\] \[immediate\]: Loads the immediate value into the register
- ADDI \[register1\] \[register2\] \[immediate\]: Adds the immediate value to register 2 and stores the result in register 1
- JMP \[address\]: Unconditional jump to address in memory
- LOAD \[register1\] \[register2\]: Read the address in register 1 from memory and store it in register 2
- WRITE \[register1\] \[register2\]: Write the value of register 2 to memory at the address in register 1
- WRITEI \[register\] \[immediate\]: Write the immediate value to memory at the address in the register

## Example code 1
The following increments r0 and outputs the result to address 1000 (Which can be wired to a display with a signal check component)
```
SET r0 0
SET r1 1000
ADDI r0 r0 1
WRITE r1 r0
JMP 2
```

## Example code 2
The following increments the address 5000 and outputs the result to address 1000 (Which can be wired to a display with a signal check component)
```
SET r0 5000
WRITEI r0 0
SET r1 1000
LOAD r0 r2
ADDI r2 r2 1
WRITE r0 r2
WRITE r1 r2
JMP 3
```

## Wiring Guide
### CPU
- Wire an oscilator with a square wave to clock_in. Don't set the frequency too high or it will become unstable.
- Wire all RAM and ROM data_out to data_in
- (Optional) Wire a button to reset_in

### Memory and Peripherals
Use a subtract component to assign memory ranges. For instance, to assign a RAM module to addresses 5000-6024, subtract 5000 from the address.