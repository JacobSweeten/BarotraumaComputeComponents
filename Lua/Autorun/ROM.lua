ROMModules = {}

Hook.Add("signalreceived.romcomponent", "signalReceivedROM", function(signal, connection)
	-- Add ROM module to list
	if ROMModules[connection.Item] == nil then
		ROMModules[connection.Item] = {
			data = {				-- Default instructions
				"SET r0 0",
				"SET r1 1000",
				"ADDI r0 r0 1",
				"OUT r1 r0",
				"JMP 2"
			},
			inputBuffer = {			-- Used to hold input data between clock cycles
				address_in = nil
			}
		}
	end

	-- Get ROM data object
	local ROMData = ROMModules[connection.Item]

	if connection.Name == "clock_in" then
		if tonumber(signal.value) == 1 then
			-- Rising edge
			
			-- Ignore until there is an address
			if ROMData.inputBuffer.address_in == nil then
				return
			end
			
			-- Send data
			connection.Item.SendSignal(tostring(ROMData.data[ROMData.inputBuffer.address_in + 1]), "data_out")
			ROMData.inputBuffer.address_in = nil
		end
	elseif connection.Name == "address_in" then
		-- Store non-empty addresses for next clock cycle
		if signal.value == "" then
			return
		end
		ROMData.inputBuffer.address_in = tonumber(signal.value)
	end
end)