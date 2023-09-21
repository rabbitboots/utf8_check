local path = ... and (...):match("(.-)[^%.]+$") or ""

local utf8Check = require(path .. "utf8_check")

local errTest = require(path .. "test.lib.err_test")
local strict = require(path .. "test.lib.strict")


--utf8Check.check(str, i, j)
do
	print("Test: " .. errTest.register(utf8Check.check, "utf8Check.check"))

	local ok, pos, err

	print("\n[-] arg #1 bad type")
	errTest.expectFail(utf8Check.check, nil)

	print("\n[-] arg #2 bad type")
	errTest.expectFail(utf8Check.check, "foobar", false)

	print("\n[-] arg #2 disallow fractional numbers")
	errTest.expectFail(utf8Check.check, "foobar", 1.5)

	print("\n[-] arg #2 too low")
	errTest.expectFail(utf8Check.check, "foobar", 0)

	print("\n[-] arg #2 too high")
	errTest.expectFail(utf8Check.check, "foobar", 2^53)

	print("\n[-] arg #3 bad type")
	errTest.expectFail(utf8Check.check, "foobar", 1, false)

	print("\n[-] arg #3 disallow fractional numbers")
	errTest.expectFail(utf8Check.check, "foobar", 1, 1.5)

	print("\n[-] arg #3 too low")
	errTest.expectFail(utf8Check.check, "foobar", 1, 0)

	print("\n[-] arg #3 too high")
	errTest.expectFail(utf8Check.check, "foobar", 1, 2^53)

	print("\n[-] arg #2 is greater than arg #3")
	errTest.expectFail(utf8Check.check, "foobar", 6, 1)

	print("\n[+] An empty string at position 1 should always be treated as a pass.")
	local empty = ""
	ok, pos, err = errTest.okErrExpectPass(utf8Check.check, empty, 1); print(ok, pos, err)

	print("\n[+] Test a string containing UTF-8 sequences 1-4 bytes in length.")
	local test_str = "@Æㇹ𐅀"
	ok, pos, err = utf8Check.check(test_str)
	if not ok then
		error("expected passing utf8Check.check() call failed: " .. pos .. ": " .. err)
	end
	print(ok, pos, err)

	print("\n[ad hoc] arg #2 misalignment (bad byte offset)")
	ok, pos, err = utf8Check.check(test_str, 3)
	if ok then
		print(ok, err)
		error("expected failing getUCString() call passed.")
	end
	print(ok, pos, err)

	print("\n[-] Arg #3 cuts off a multi-byte UTF-8 sequence")
	local cutoff_str = "@Æㇹ𐅀"
	ok, pos, err = errTest.okErrExpectFail(utf8Check.check, cutoff_str, 2, 2); print(ok, pos, err)

	print("\n[+] (Correct version of the above)")
	local cutoff_str = "@Æㇹ𐅀"
	ok, pos, err = errTest.okErrExpectPass(utf8Check.check, cutoff_str, 2, 3); print(ok, pos, err)

	print("\n[-] Arg #1 contains Nul as continuation byte (\\0)")
	local ok_string  = "aaaa\xC3\x86aaaa" -- Æ
	ok, pos, err = errTest.okErrExpectPass(utf8Check.check, ok_string, 5); print(ok, pos, err)

	local bad_string = "aaaa\xC3\000aaaa"
	ok, pos, err = errTest.okErrExpectFail(utf8Check.check, bad_string, 5); print(ok, pos, err)

	print("\n[+] Arg #1 acceptable use of Nul (\\0)")
	local ok_nul = "aaaa\000aaaa"
	ok, pos, err = errTest.okErrExpectPass(utf8Check.check, ok_nul, 5); print(ok, pos, err)

	print("\n[-] Arg #1 contains surrogate range code points")
	local surr = "a\xED\xA0\x80b"
	ok, pos, err = errTest.okErrExpectFail(utf8Check.check, surr, 2); print(ok, pos, err)

	print("\n[+] Test a slightly longer string (but not so large that it overwhelms the console)")
	local big_str = "Row, row, row your boat\nGently down the stream\nMerrily merrily merrily merrily merrily\nlife is but a dream\n"
	print("#big_str", #big_str)
	ok, pos, err = errTest.okErrExpectPass(utf8Check.check, big_str); print(ok, pos, err)
end

