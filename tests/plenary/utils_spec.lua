local utils = require("anki.utils")
local notification = require("anki.notification")
local spy = require("luassert.spy")

describe("anki.utils", function()
  describe("split", function()
    it("splits by whitespace by default", function()
      assert.are.same({ "a", "b", "c" }, utils.split("a b c"))
    end)

    it("splits by a custom separator", function()
      assert.are.same({ "a", "b", "c" }, utils.split("a,b,c", ","))
    end)

    it("returns a single-element table for a string with no separator", function()
      assert.are.same({ "hello" }, utils.split("hello"))
    end)

    it("returns an empty table for an empty string", function()
      assert.are.same({}, utils.split(""))
    end)

    it("throws error when inputstr is not a string", function()
      assert.has_error(function()
        utils.split(123)
      end, "[anki.nvim][utils] split: inputstr must be a string")
    end)

    it("throws error when sep is not a string or nil", function()
      assert.has_error(function()
        utils.split("a,b", 42)
      end, "[anki.nvim][utils] split: sep must be a string or nil")
    end)
  end)

  describe("safe_call", function()
    it("returns the result when there is no error", function()
      local fn = function()
        return { result = "success", error = vim.NIL }
      end
      assert.are.equal("success", utils.safe_call(fn))
    end)

    it("returns nil and notifies on pcall failure", function()
      local fn = function()
        error("something went wrong")
      end
      local error_spy = spy.on(notification, "error")
      local result = utils.safe_call(fn)
      assert.is_nil(result)
      assert.spy(error_spy).was.called()
      error_spy:revert()
    end)

    it("returns nil and notifies on AnkiConnect error", function()
      local fn = function()
        return { result = nil, error = "anki error" }
      end
      local error_spy = spy.on(notification, "error")
      local result = utils.safe_call(fn)
      assert.is_nil(result)
      assert.spy(error_spy).was.called()
      error_spy:revert()
    end)

    it("throws error when fn is not a function", function()
      assert.has_error(function()
        utils.safe_call("not a function")
      end, "[anki.nvim][utils] safe_call: fn must be a function")
    end)

    it("passes arguments to the function", function()
      local fn = function(a, b)
        return { result = a + b, error = vim.NIL }
      end
      assert.are.equal(5, utils.safe_call(fn, 2, 3))
    end)

    it("returns result when response has no error field", function()
      local fn = function()
        return { result = "success" }
      end
      assert.are.equal("success", utils.safe_call(fn))
    end)
  end)

  describe("escape_search_query", function()
    it("escapes double quotes in search queries", function()
      local result = utils.escape_search_query('deck:"My Deck"')
      assert.are.equal('deck:\\"My Deck\\"', result)
    end)

    it("escapes backslashes in search queries", function()
      local result = utils.escape_search_query([[My\Deck]])
      assert.are.equal([[My\\Deck]], result)
    end)

    it("escapes both backslashes and quotes together", function()
      local result = utils.escape_search_query([[My\"Deck]])
      assert.are.equal([[My\\\"Deck]], result)
    end)

    it("returns the string unchanged when no special characters", function()
      assert.are.equal("Default", utils.escape_search_query("Default"))
    end)
  end)
end)