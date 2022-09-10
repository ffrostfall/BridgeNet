return function()
	local Symbols = {}

	for k, v in script:GetChildren() do
		Symbols[k] = require(v)
	end

	return Symbols
end
