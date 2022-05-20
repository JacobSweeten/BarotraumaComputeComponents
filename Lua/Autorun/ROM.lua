ROMModules = {}

Hook.Add("signalreceived.romcomponent", "signalReceivedROM", function(signal, connection)
	if ROMModules[connection.Item] == nil then
		ROMModules[connection.Item] = {
			data = {
				"SET r0 0",
				"SET r1 1000",
				"ADDI r0 r0 1",
				"OUT r1 r0",
				"JMP 2"
			},
			inputBuffer = {
				address_in = nil
			}
		}
	end

	local ROMData = ROMModules[connection.Item]

	if connection.Name == "clock_in" then
		if ROMData.inputBuffer.address_in == nil then
			return
		end

		connection.Item.SendSignal(tostring(ROMData.data[ROMData.inputBuffer.address_in + 1]), "data_out")
		ROMData.inputBuffer.address_in = nil
	elseif connection.Name == "address_in" then
		if signal.value == "" then
			return
		end
		ROMData.inputBuffer.address_in = tonumber(signal.value)
	end
end)