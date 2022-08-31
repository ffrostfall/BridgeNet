return function()
	local Symbols = {}

	for k, v in script:GetChildren() do
		Symbols[k] = v
	end

	return Symbols
end
