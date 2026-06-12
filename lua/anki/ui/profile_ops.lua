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
	utils.async_safe_call(ankiconnect.get_active_profile, nil, function(active_profile, error)
		if error or not active_profile then
			notification.error("[anki.nvim][profile_ops] Failed to get active profile")
			return
		end

		utils.async_safe_call(ankiconnect.get_profiles, nil, function(profiles, err2)
			if err2 or not profiles or #profiles == 0 then
				notification.warn("[anki.nvim][profile_ops] No profiles found")
				return
			end

			vim.schedule(function()
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
						utils.async_safe_call(ankiconnect.load_profile, { selected_profile }, function(result, err3)
							if err3 or result == nil then
								notification.error(
									"[anki.nvim][profile_ops] Failed to switch to profile '" .. selected_profile .. "'"
								)
								return
							end

							notification.info(
								"[anki.nvim][profile_ops] Switched to profile '" .. selected_profile .. "'"
							)

							anki_state.ui.current_filter = "deck:*"

							local max_attempts = 50
							local attempt = 0
							local check_interval = 100

							local function check_profile_changed()
								attempt = attempt + 1
								utils.async_safe_call(
									ankiconnect.get_active_profile,
									nil,
									function(switched_profile, profile_err)
										if profile_err or not switched_profile then
											notification.error("[anki.nvim][profile_ops] Failed to get active profile")
											return
										end

										if switched_profile == selected_profile then
											vim.schedule(function()
												operations.refresh_all()
											end)
										elseif attempt < max_attempts then
											vim.defer_fn(check_profile_changed, check_interval)
										else
											notification.error("[anki.nvim][profile_ops] Profile switch timed out")
										end
									end
								)
							end

							vim.defer_fn(check_profile_changed, check_interval)
						end)
					end

					if next(anki_state.current_notes) then
						vim.ui.input(
							{ prompt = "Save changes to open notes before switching profile? (Y/n): " },
							function(input)
								if input == nil then
									return
								end

								if input == "Y" or input == "y" or input == "" then
									for _, note in pairs(anki_state.current_notes) do
										api.send_note(note.tags.bufnr)
									end
								end
								editor.kill_all()
								do_profile_switch()
							end
						)
					else
						do_profile_switch()
					end
				end)
			end)
		end)
	end)
end

return M
