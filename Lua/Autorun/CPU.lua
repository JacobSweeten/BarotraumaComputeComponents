local CPUs = {}

local CPUStates = {
	FETCH_INSTRUCTION_SIGOUT = 0,
	FETCH_INSTRUCTION_SIGIN = 1,
	EXEC_INSTRUCTION = 2,
	READ_MEMORY_SIGOUT = 3,
	READ_MEMORY_SIGIN = 4,
}

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

Hook.Add("signalReceived.cpucomponent", "signalReceivedCPU", function(signal, connection)
	if CPUs[connection.Item] == nil then
		CPUs[connection.Item] = {
			registers = {},
			PC = 0,
			flags = {
				overflow = false
			},
			state = CPUStates.FETCH_INSTRUCTION_SIGOUT,
			inputBuffer = {
				data_in = nil,
				interrupt_in = nil
			},
			currentInstruction = ""
		}
	end

	CPUData = CPUs[connection.Item]

	if connection.Name == "clock_in" then
		if tonumber(signal.value) == 1 then
			-- Rising edge
			if CPUData.state == CPUStates.FETCH_INSTRUCTION_SIGOUT then
				connection.Item.SendSignal(tostring(CPUData.PC), "address_out")
				print("Fetching instruction at address: " .. tostring(CPUData.PC))
				CPUData.state = CPUStates.FETCH_INSTRUCTION_SIGIN
			elseif CPUData.state == CPUStates.FETCH_INSTRUCTION_SIGIN then
				if CPUData.inputBuffer.data_in == nil then
					return
				end
				CPUData.currentInstruction = CPUData.inputBuffer.data_in
				CPUData.inputBuffer.data_in = nil
				print("Got instruction: " .. CPUData.currentInstruction)
				CPUData.state = CPUStates.EXEC_INSTRUCTION
			elseif CPUData.state == CPUStates.EXEC_INSTRUCTION then
				local instructionFinished = true
				local incrementPC = true
				print("Executing instruction...")

				local instructionArr = split(CPUData.currentInstruction, " ")

				if instructionArr[1] == "SET" then
					setRegister(CPUData, instructionArr[2], tonumber(instructionArr[3]))
				elseif instructionArr[1] == "ADDI" then
					setRegister(CPUData, instructionArr[2], getRegister(CPUData, instructionArr[3]) + tonumber(instructionArr[4]))
				elseif instructionArr[1] == "JMP" then
					CPUData.PC = instructionArr[2]
					incrementPC = false
				elseif instructionArr[1] == "OUT" then
					connection.Item.SendSignal(getRegister(CPUData, instructionArr[2]), "address_out")
					connection.Item.SendSignal(getRegister(CPUData, instructionArr[3]), "data_out")
				end
				
				if incrementPC then
					CPUData.PC = CPUData.PC + 1
				end

				if instructionFinished then
					CPUData.state = CPUStates.FETCH_INSTRUCTION_SIGOUT
				end
			end
		elseif tonumber(signal.value) == 0 then
			-- Falling edge
		else
			-- Invalid input
		end
	elseif connection.Name == "data_in" then
		CPUData.inputBuffer.data_in = signal.value
	elseif connection.Name == "interrupt_in" then
		CPUData.inputBuffer.interrupt_in = signal.value
	end
end)