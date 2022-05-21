local RAMModules = {}

Hook.Add("signalreceived.ramcomponent", "signalReceivedRAM", function(signal, connection)
	-- Add RAM module to list
	if RAMModules[connection.Item] == nil then
		RAMModules[connection.Item] = {
			data = {},				-- RAM storage
			inputBuffer = {			-- Used to hold input data between clock cycles
				address_in = nil,
				write_enable_in = nil,
				data_in = nil
			}
		}
	end

	-- Get ROM data object
	local RAMData = RAMModules[connection.Item]

	if connection.Name == "clock_in" then
		if tonumber(signal.value) == 1 then
			-- Rising edge
			
			-- Ignore until there is an address
			if RAMData.inputBuffer.address_in == nil then
				return
			end

			-- Check if write_enable is set
			if RAMData.inputBuffer.write_enable == 1 then
				-- Make sure we actually have data to input
				if RAMData.inputBuffer.data_in ~= nil then
					ROMData.data[RAMData.inputBuffer.address_in + 1] = RAMData.inputBuffer.data_in
					RAMData.inputBuffer.data_in = nil
				end
				RAMData.inputBuffer.write_enable_in = nil
			else
				-- Send data
				connection.Item.SendSignal(tostring(RAMData.data[RAMData.inputBuffer.address_in + 1]), "data_out")
				RAMData.inputBuffer.address_in = nil
			end
		end
	elseif connection.Name == "address_in" then
		-- Store non-empty addresses for next clock cycle
		if signal.value == "" then
			return
		end
		RAMData.inputBuffer.address_in = tonumber(signal.value)
	elseif connection.Name == "write_enable_in" then
		-- Store write enable for next clock cycle
		RAMData.inputBuffer.write_enable_in = tonumber(signal.value)
	elseif connection.Name == "data_in" then
		-- Store data for next clock cycle
		RAMData.inputBuffer.write_enable_in = tonumber(signal.value)
	end
end)