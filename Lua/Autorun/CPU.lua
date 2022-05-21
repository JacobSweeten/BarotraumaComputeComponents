local CPUs = {}

-- Used to determine what to do each clock cycle
local CPUStates = {
	FETCH_FIRST_INSTRUCTION = 0,
	FETCH_INSTRUCTION_SIGIN = 1,
	WRITE_MEMORY_SIGOUT = 2,
	READ_MEMORY_SIGIN = 3,
}

-- Helpful for parsing instructions
function split(str, char)
	local out = {}

	local temp = ""

	for i = 1, string.len(str) do
		local c = string.sub(str, i, i)
		if c == char then
			table.insert(out, temp)
			temp = ""
		else
			temp = temp .. c
		end
	end

	table.insert(out, temp)

	return out
end

function setRegister(CPUData, reg, val)
	local register = tonumber(string.sub(reg, 2, string.len(reg))) + 1
	CPUData.registers[register] = val
end

function getRegister(CPUData, reg)
	local register = tonumber(string.sub(reg, 2, string.len(reg))) + 1
	return CPUData.registers[register]
end

function fetchInstruction(CPUItem, CPUData)
	-- Send PC as address for memory read
	CPUItem.SendSignal(tostring(CPUData.PC), "address_out")
	print("Fetching instruction at address: " .. tostring(CPUData.PC))
	-- Set CPU to read the instruction next clock cycle
	CPUData.state = CPUStates.FETCH_INSTRUCTION_SIGIN
end

Hook.Add("signalReceived.cpucomponent", "signalReceivedCPU", function(signal, connection)
	-- Add CPU to list
	if CPUs[connection.Item] == nil then
		CPUs[connection.Item] = {
			registers = {								-- Array of registers
				0, 0, 0, 0, 0, 0, 0, 0,
				0, 0, 0, 0, 0, 0, 0, 0},
			PC = 0,										-- Program counter
			flags = {									-- CPU Flags
				overflow = false
			},
			state = CPUStates.FETCH_FIRST_INSTRUCTION,	-- CPU State
			inputBuffer = {								-- Used to hold input data between clock cycles
				data_in = nil,
				interrupt_in = nil
			},
			currentInstruction = ""						-- Whatever the current fetched instruction is
		}
	end

	-- Get CPU data object
	CPUData = CPUs[connection.Item]

	if connection.Name == "clock_in" then
		if tonumber(signal.value) == 1 then
			-- Rising edge
			if CPUData.state == CPUStates.FETCH_FIRST_INSTRUCTION then
				fetchInstruction(connection.Item, CPUData)
			elseif CPUData.state == CPUStates.FETCH_INSTRUCTION_SIGIN then
				-- Do nothing until data has been received
				if CPUData.inputBuffer.data_in == nil then
					return
				end

				local instructionFinished = true	-- In case of memory read instructions
				local incrementPC = true			-- In case of jump instructions

				-- Read in instruction
				CPUData.currentInstruction = CPUData.inputBuffer.data_in
				CPUData.inputBuffer.data_in = nil
				print("Got instruction: " .. CPUData.currentInstruction)

				local instructionArr = split(CPUData.currentInstruction, " ")

				-- Parse instruction
				if instructionArr[1] == "SET" then
					setRegister(CPUData, instructionArr[2], tonumber(instructionArr[3]))
				elseif instructionArr[1] == "ADDI" then
					setRegister(CPUData, instructionArr[2], getRegister(CPUData, instructionArr[3]) + tonumber(instructionArr[4]))
				elseif instructionArr[1] == "JMP" then
					CPUData.PC = instructionArr[2]
					incrementPC = false
				elseif instructionArr[1] == "WRITEI" then
					connection.Item.SendSignal(tostring(getRegister(CPUData, instructionArr[2])), "address_out")
					connection.Item.SendSignal(instructionArr[3], "data_out")
					connection.Item.SendSignal("1", "write_enable_out")
					CPUData.state = CPUStates.WRITE_MEMORY_SIGOUT
					incrementPC = false
					instructionFinished = false
				elseif instructionArr[1] == "WRITE" then
					connection.Item.SendSignal(tostring(getRegister(CPUData, instructionArr[2])), "address_out")
					connection.Item.SendSignal(tostring(getRegister(CPUData, instructionArr[3])), "data_out")
					connection.Item.SendSignal("1", "write_enable_out")
					CPUData.state = CPUStates.WRITE_MEMORY_SIGOUT
					incrementPC = false
					instructionFinished = false
				elseif instructionArr[1] == "LOAD" then
					connection.Item.SendSignal(tostring(getRegister(CPUData, instructionArr[2])), "address_out")
					connection.Item.SendSignal("0", "write_enable_out")
					CPUData.state = CPUStates.READ_MEMORY_SIGIN
					incrementPC = false
					instructionFinished = false
				end
				
				-- Increment PC if not a jump instruction
				if incrementPC then
					CPUData.PC = CPUData.PC + 1
				end

				if instructionFinished then
					fetchInstruction(connection.Item, CPUData)
				end
			elseif CPUData.state == CPUStates.WRITE_MEMORY_SIGOUT then
				CPUData.PC = CPUData.PC + 1
				fetchInstruction(connection.Item, CPUData)
			elseif CPUData.state == CPUStates.READ_MEMORY_SIGIN then
				-- Wait for data
				if CPUData.inputBuffer.data_in == nil then
					return
				end

				local instructionArr = split(CPUData.currentInstruction, " ")

				setRegister(CPUData, instructionArr[3], CPUData.inputBuffer.data_in)
				CPUData.inputBuffer.data_in = nil

				CPUData.PC = CPUData.PC + 1
				fetchInstruction(connection.Item, CPUData)
			end
		elseif tonumber(signal.value) == 0 then
			-- Falling edge
		else
			-- Invalid input
		end
	elseif connection.Name == "data_in" then
		-- Read data into buffer only when expecting data
		if CPUData.state == CPUStates.FETCH_INSTRUCTION_SIGIN then
			CPUData.inputBuffer.data_in = signal.value
		elseif CPUData.state == CPUStates.READ_MEMORY_SIGIN then
			CPUData.inputBuffer.data_in = tonumber(signal.value)
		end
	elseif connection.Name == "interrupt_in" then
		-- Read interrupt into buffer
		CPUData.inputBuffer.interrupt_in = signal.value
	elseif connection.Name == "reset_in" then
		if tonumber(signal.value) == 1 then
			-- Reset
			CPUs[connection.Item] = nil
		end
	end
end)