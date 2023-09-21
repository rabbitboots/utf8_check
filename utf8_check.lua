-- utf8Check version: 1.0.0
-- Based on utf8Tools: https://github.com/rabbitboots/utf8_tools
--[[
	MIT License

	Copyright (c) 2022, 2023 RBTS

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
--]]

local utf8Check = {}

utf8Check.check_surrogates = true

local function errBadType(arg_n, val, expected)
	error("argument #" .. arg_n .. ": bad type (Expected " .. expected .. ", got " .. type(val) .. ")", 2)
end

local function errBadIntRange(arg_n, val, min, max)
	error("argument #" .. arg_n .. ": expected integer in range (" .. min .. "-" .. max .. ")", 2)
end

local lut_invalid_octet = {}
for i, v in ipairs({0xc0, 0xc1, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff}) do
	lut_invalid_octet[v] = true
end

local lut_oct_min_max = {{0x00000, 0x00007f}, {0x00080, 0x0007ff}, {0x00800, 0x00ffff}, {0x10000, 0x10ffff}}

local function getLengthMarker(byte)
	return (byte < 0x80) and 1
	or (byte >= 0xC0 and byte < 0xE0) and 2
	or (byte >= 0xE0 and byte < 0xF0) and 3
	or (byte >= 0xF0 and byte < 0xF8) and 4
	or "parse length failed"
end

local function _numberFromOctets(n_octets, b1, b2, b3, b4)
	return n_octets == 1 and b1
	or n_octets == 2 and (b1 - 0xc0) * 0x40 + (b2 - 0x80)
	or n_octets == 3 and (b1 - 0xe0) * 0x1000 + (b2 - 0x80) * 0x40 + (b3 - 0x80)
	or n_octets == 4 and (b1 - 0xf0) * 0x40000 + (b2 - 0x80) * 0x1000 + (b3 - 0x80) * 0x40 + (b4 - 0x80)
	or nil
end

local function _checkFollowingOctet(octet, position, n_octets)

	if not octet then
		return "Octet #" .. tostring(position) .. " is nil."

	-- Check some bytes which are prohibited in any position in a UTF-8 code point
	elseif lut_invalid_octet[octet] then
		return "Invalid octet value (" .. octet .. ") in byte #" .. position

	-- Nul is allowed in single-octet code points, but not multi-octet
	elseif octet == 0 then
		return "Octet #" .. tostring(position) .. ": Multi-byte code points cannot contain 0 / Nul bytes."

	-- Verify "following" byte mark	
	-- < 1000:0000
	elseif octet < 0x80 then
		return "Byte #" .. tostring(position) .. " is too low (" .. tostring(octet) .. ") for multi-byte encoding. Min: 0x80"

	-- >= 1100:0000
	elseif octet >= 0xC0 then
		return "Byte #" .. tostring(position) .. " is too high (" .. tostring(octet) .. ") for multi-byte encoding. Max: 0xBF"
	end
end

local function _checkCodePointIssue(code_point, u8_len)

	if utf8Check.check_surrogates then
		if code_point >= 0xd800 and code_point <= 0xdfff then
			return false, "UTF-8 prohibits values between 0xd800 and 0xdfff (the surrogate range.) Received: "
				.. string.format("0x%x", code_point)
		end
	end

	local min_max = lut_oct_min_max[u8_len]
	if code_point < min_max[1] or code_point > min_max[2] then
		return false, u8_len .. "-octet length mismatch. Got: " .. code_point
			.. ", must be in this range: " .. min_max[1] .. " - " .. min_max[2]
	end

	return true
end

function utf8Check.check(str, i, j)

	local str_max = math.max(1, #str)
	if i == nil then i = 1 end
	if j == nil then j = str_max end

	-- Assertions
	-- [[
	if type(str) ~= "string" then errBadType(1, str, "string")
	elseif type(i) ~= "number" or i ~= math.floor(i) then errBadType(2, i, "(whole) number")
	elseif i < 1 or i > str_max then errBadIntRange(2, i, 1, str_max)
	elseif type(j) ~= "number" or j ~= math.floor(j) then errBadType(3, j, "(whole) number")
	elseif j < 1 or j > str_max then errBadIntRange(3, j, 1, str_max)
	elseif i > j then error("start index 'i' (" .. i .. ") is greater than final index 'j' (" .. j .. ").") end
	--]]

	-- Empty string
	if i == 1 and #str == 0 then
		return true
	end

	while i <= j do
		local b1, b2, b3, b4 = string.byte(str, i, math.min(i + 3, j))
		local u8_len = getLengthMarker(b1)
		if type(u8_len) == "string" then
			return false, i, u8_len

		elseif lut_invalid_octet[b1] then
			return false, i, "Invalid octet value (" .. b1 .. ") in byte #1"
		end

		local code_point
		local err_str

		if u8_len == 1 then
			code_point = b1

		elseif u8_len == 2 then
			err_str = _checkFollowingOctet(b2, 2, 2) if err_str then return false, i, err_str end
			code_point = (b1 - 0xc0) * 0x40 + (b2 - 0x80)

		elseif u8_len == 3 then
			err_str = _checkFollowingOctet(b2, 2, 3) if err_str then return false, i, err_str end
			err_str = _checkFollowingOctet(b3, 3, 3) if err_str then return false, i, err_str end
			code_point = (b1 - 0xe0) * 0x1000 + (b2 - 0x80) * 0x40 + (b3 - 0x80)

		elseif u8_len == 4 then
			err_str = _checkFollowingOctet(b2, 2, 4) if err_str then return false, i, err_str end
			err_str = _checkFollowingOctet(b3, 3, 4) if err_str then return false, i, err_str end
			err_str = _checkFollowingOctet(b4, 4, 4) if err_str then return false, i, err_str end
			code_point = (b1 - 0xf0) * 0x40000 + (b2 - 0x80) * 0x1000 + (b3 - 0x80) * 0x40 + (b4 - 0x80)
		end

		local code_ok, code_err = _checkCodePointIssue(code_point, u8_len)
		if not code_ok then
			return false, i, code_err
		end

		i = i + u8_len
	end

	return true
end

return utf8Check
