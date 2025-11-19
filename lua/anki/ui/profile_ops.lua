local notification = require("anki.notification")
local utils = require("anki.utils")
local ankiconnect = require("anki.ankiconnect")
local operations = require("anki.ui.operations")
local anki_state = require("anki.state")
local api = require("anki.api")
local editor = require("anki.editor")

local M = {}

---
--- Prompts the user to switch to a different Anki profile.
--- Gets the list of available profiles and shows a selection dialog.
--- After switching, refreshes the UI to show the new profile's data.
---
function M.switch_profile()
	local active_profile = utils.safe_call(ankiconnect.get_active_profile)
	if not active_profile then
		notification.error("[anki.nvim][profile_ops] Failed to get active profile")
		return
	end

	local profiles = utils.safe_call(ankiconnect.get_profiles)
	if not profiles or #profiles == 0 then
		notification.warn("[anki.nvim][profile_ops] No profiles found")
		return
	end

	vim.ui.select(profiles, {
		prompt = "Switch to profile (current: " .. active_profile .. "):",
		format_item = function(profile)
			if profile == active_profile then
				return profile .. " (current)"
			end
			return profile
		end,
	}, function(selected_profile)
		if not selected_profile then
			return
		end

		if selected_profile == active_profile then
			notification.info("[anki.nvim][profile_ops] Already using profile '" .. selected_profile .. "'")
			return
		end

		local function do_profile_switch()
			local result = utils.safe_call(ankiconnect.load_profile, selected_profile)
			if result == nil then
				notification.error("[anki.nvim][profile_ops] Failed to switch to profile '" .. selected_profile .. "'")
				return
			end

			notification.info("[anki.nvim][profile_ops] Switched to profile '" .. selected_profile .. "'")

			anki_state.ui.current_filter = "deck:*"

			-- Wait for profile to properly change before refreshing (with timeout)
			local max_attempts = 50
			local attempt = 0
			local check_interval = 100 -- milliseconds

			local function check_profile_changed()
				attempt = attempt + 1
				local switched_profile = utils.safe_call(ankiconnect.get_active_profile)

				if not switched_profile then
					notification.error("[anki.nvim][profile_ops] Failed to get active profile")
					return
				end

				if switched_profile == selected_profile then
					operations.refresh_all()
				elseif attempt < max_attempts then
					vim.defer_fn(check_profile_changed, check_interval)
				else
					notification.error("[anki.nvim][profile_ops] Profile switch timed out")
				end
			end

			vim.defer_fn(check_profile_changed, check_interval)
		end

		if anki_state.current_note then
			vim.ui.input({ prompt = "Save changes to current note before switching profile? (Y/n): " }, function(input)
				if input == nil then
					return
				end

				if input == "Y" or input == "y" or input == "" then
					api.send_note(anki_state.current_note.tags.bufnr)
				end
				editor.kill_note(anki_state.current_note.tags.bufnr)
				do_profile_switch()
			end)
		else
			do_profile_switch()
		end
	end)
end

return M
