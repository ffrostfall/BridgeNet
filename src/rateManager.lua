--[=[
	@class RateManager
	
	Manages the send and receive rates. Functions are basic setters and getters.
]=]
local RateManager = {}

local sendRate: number = 60
local receiveRate: number = 60

--[=[
	Sets the rate (in Hz) of which connections are executed
	
	```lua
		RateManager.SetReceiveRate(30) -- Do connections at 30 fps
	```
	
	@param rate number
	@return nil
]=]
function RateManager.SetReceiveRate(rate: number): nil
	receiveRate = rate
	return nil
end

--[=[
	Sets the rate (in Hz) of which remotes are fired
	
	```lua
		RateManager.SetSendRate(30) -- Do connections at 30 fps
	```
	
	@param rate number
	@return nil
]=]
function RateManager.SetSendRate(rate: number): nil
	sendRate = rate
	return nil
end

--[=[
	Returns the current rate of which connections are handled.
	
	```lua
		print(RateManager.GetReceiveRate()) -- Prints 60
	```
	
	@return number
]=]
function RateManager.GetReceiveRate(): number
	return 1 / receiveRate
end

--[=[
	Returns the current rate of which remotes are fired
	
	```lua
		print(RateManager.GetSendRate()) -- Prints 60
	```
	
	@return number
]=]
function RateManager.GetSendRate(): number
	return 1 / sendRate
end

return RateManager
