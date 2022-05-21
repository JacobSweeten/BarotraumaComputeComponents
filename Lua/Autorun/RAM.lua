local RAMModules = {}

Hook.Add("signalreceived.ramcomponent", "signalReceivedRAM", function(signal, connection)
	-- Add RAM module to list
	if RAMModules[connection.Item] == nil then
		RAMModules[connection.Item] = {
			data = {},				-- RAM storage
			inputBuffer = {			-- Used to hold input data between clock cycles
				address_in = nil,
				write_enable_in = 0,
				data_in = nil
			}
		}

		-- Initialize to 0
		for i = 1, 1024 do
			RAMModules[connection.Item].data[i] = 0
		end
	end

	-- Get RAM data object
	local RAMData = RAMModules[connection.Item]

	if connection.Name == "clock_in" then
		if tonumber(signal.value) == 1 then
			-- Rising edge
			
			-- Ignore until there is a valid address
			if RAMData.inputBuffer.address_in == nil or RAMData.inputBuffer.address_in < 0 or RAMData.inputBuffer.address_in > 1024 then
				return
			end

			-- Check if write_enable_in is set
			if RAMData.inputBuffer.write_enable_in == 1 then
				-- Make sure we actually have data to input
				if RAMData.inputBuffer.data_in ~= nil then
					RAMData.data[RAMData.inputBuffer.address_in + 1] = RAMData.inputBuffer.data_in
					RAMData.inputBuffer.data_in = nil
				end
			else
				-- Send data if there is an address
				if RAMData.inputBuffer.address_in == nil then
					return
				end

				connection.Item.SendSignal(tostring(RAMData.data[RAMData.inputBuffer.address_in + 1]), "data_out")
			end

			RAMData.inputBuffer.address_in = nil
			RAMData.inputBuffer.write_enable_in = 0
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
		RAMData.inputBuffer.data_in = tonumber(signal.value)
	end
end)