local inspect = require"inspect"

function mod()
	jack_client = {}

	function jack_client:new(name)
	  jack_client = {client_name = name}
	  self.__index = self
	  return setmetatable(jack_client, self)
	end

	function jack_client:foo()
		print("bar")
	end

	function jack_client:spam()
		print("ham")
	end

	function jack_client:print_name()
		print(self.client_name)
	end

	function jack_client:inspect()
		print(inspect(self))
	end

	return setmetatable({}, {
	__call = function (tbl, ...)
		return jack_client:new(...)
	end
	})
end

-- Test
local jack_client = mod()

local cli = jack_client("lol")
cli:foo()
cli:spam()
cli:inspect()
cli:print_name()
