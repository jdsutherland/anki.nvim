local utils = require("anki.utils")
local spy = require("luassert.spy")

describe("anki.utils", function()
	describe("split", function()
		it("should split a string by whitespace by default", function()
			assert.are.same({ "a", "b", "c" }, utils.split("a b c"))
		end)

		it("should split a string by a given separator", function()
			assert.are.same({ "a", "b", "c" }, utils.split("a,b,c", ","))
		end)
	end)

	describe("safe_call", function()
		it("should return the result of the function if there is no error", function()
			local fn = function()
				return { result = "success", error = vim.NIL }
			end
			assert.are.equal("success", utils.safe_call(fn))
		end)

		it("should return nil and show an error notification if there is an error", function()
			local fn = function()
				return { result = nil, error = "error" }
			end
			local notification = require("anki.notification")
			local error_spy = spy.on(notification, "error")
			assert.is_nil(utils.safe_call(fn))
			assert.spy(error_spy).was.called_with('[anki.nvim][utils] "error"')
		end)
	end)
end)
