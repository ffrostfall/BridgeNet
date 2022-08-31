local SerdesLayer = require(script.Parent.SerdesLayer)

return function(tbl: { string })
	local ReturnValue = {}
	
	for _, v in tbl do
		ReturnValue[v] = SerdesLayer.CreateIdentifier(v)
	end
	
	return ReturnValue :: {[string]: string}
end
