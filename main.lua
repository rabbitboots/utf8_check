--[[
Tests 4294967296 combinations of 1-4 bytes, passing them to LÖVE and utf8Check as
UTF-8 sequences to compare validation results.

If utf8Check passes any combo that LÖVE rejects, the test is considered a failure.
LÖVE error messages are drawn on the left, while utf8Check errors are on the right.


Super basic controls:

up/down: scroll the error messages
-/=: decrease or increase the number of messages drawn (for performance reasons)
escape: quit

Upon completion, the total time spent is printed to the console.
--]]

local time_start = love.timer.getTime()

love.keyboard.setKeyRepeat(true)

local w1 = {"Fantastic", "Bombastic", "Terrific", "Emphatic", "Automatic", "Risible"}
local w2 = {"utf8Check"}
local w3 = {"Tester", "Gauntlet", "Cyclone", "Tempest", "Thunderdome"}

local rnd = love.math.random
love.window.setTitle("The " .. w1[rnd(1, #w1)] .. " " .. w2[rnd(1, #w2)] .. " " .. " " .. w3[rnd(1, #w3)])


local utf8 = require("utf8")

local utf8Check = require("utf8_check")


local scroll_y = 0
local max_err_draw = 16

local counter = 0
local bytes = {0}
local done = false

local n_mismatches = 0
local love_errs = {}
local uc_errs = {}

local n_love_err = 0
local n_uc_err = 0

local font = love.graphics.newFont(16)


local function cycle()

	for i = #bytes, 1, -1 do
		bytes[i] = nil
	end

	local val = counter
	while val > 0 do
		table.insert(bytes, val % 256)
		val = math.floor(val / 256)
	end

	local str = ""
	for i = 1, #bytes do
		str = str .. string.char(bytes[i])
	end

	local font_getWidth = font.getWidth
	local love_ok, love_err = pcall(font_getWidth, font, str)

	local uc_ok, uc_pos, uc_err = utf8Check.check(str)

	if not love_ok then
		n_love_err = n_love_err + 1
	end
	if not uc_ok then
		n_uc_err = n_uc_err + 1
	end

	if (not not love_ok) ~= (not not uc_ok) then
		if not love_ok then
			--print("LÖVE error: " .. love_err)
			love_errs[love_err] = love_errs[love_err] and love_errs[love_err] + 1 or 1
		end
		if not uc_ok then
			--print("UC error: " .. uc_pos or "...", uc_err)
			uc_errs[uc_err] = uc_errs[uc_err] and uc_errs[uc_err] + 1 or 1
		end
		n_mismatches = n_mismatches + 1
	end

	counter = counter + 1

	-- Done.
	if counter > 2^32 then
		return true
	end
end


function love.keypressed(kc, sc)

	if kc == "escape" then
		love.event.quit()

	elseif kc == "up" then
		scroll_y = scroll_y + 256

	elseif kc == "down" then
		scroll_y = scroll_y - 256

	elseif kc == "-" then
		max_err_draw = math.max(1, max_err_draw - 1)

	elseif kc == "=" then
		max_err_draw = math.min(10000, max_err_draw + 1)
	end
end


function love.update(dt)

	if not done then
		for i = 1, 65536 do
			if cycle() then
				done = true
				print("Complete. Total time: " .. love.timer.getTime() - time_start)
				break
			end
		end
	end
end


function love.draw()

	love.graphics.print("# Mismatches: " .. n_mismatches, 32, 32)
	love.graphics.print("counter: " .. counter, 32, 64)
	love.graphics.print("Error count: LÖVE: " .. n_love_err .. ", UC: " .. n_uc_err .. ", delta: " .. math.abs(n_love_err - n_uc_err), 32, 96)

	local xx = 32
	local yy = scroll_y + 128
	for k, v in pairs(love_errs) do
		love.graphics.print(k .. ": " .. v, xx, yy)
		yy = yy + 12
	end

	xx = 400
	yy = scroll_y + 128
	local draw_n = 0
	for k, v in pairs(uc_errs) do
		draw_n = draw_n + 1
		if draw_n > max_err_draw then
			break
		end
		love.graphics.print(k .. ": " .. v, xx, yy)
		yy = yy + 12
	end	
end

