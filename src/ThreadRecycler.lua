local ThreadRecycler = {}
ThreadRecycler.__index = ThreadRecycler

local function functionPasser(fn, ...)
	fn(...)
end

local function yielder()
	while true do
		functionPasser(coroutine.yield())
	end
end

function ThreadRecycler.new()
	local self = setmetatable({}, ThreadRecycler)

	self._freeThread = nil

	return self
end

function ThreadRecycler:Spawn(fn, ...)
	if not self._freeThread then
		self._freeThread = coroutine.create(yielder)
		coroutine.resume(self._freeThread)
	end
	local acquiredThread = self._freeThread
	self._freeThread = nil
	task.spawn(acquiredThread, fn, ...)
	self._freeThread = acquiredThread
end

return ThreadRecycler
