**Version 1.0.0**

# utf8Check

Checks the encoding and code points in a UTF-8 string. Returns a byte position if the string is invalid.

The intended use case is to check strings which may be passed to LÖVE text functions (e.g. `love.graphics.print()`). (`uft8.len()` checks the UTF-8 encoding, but it also allows some invalid code points which will raise an error.)

While the checker is more strict than LÖVE, it should not pass any UTF-8 sequence that LÖVE would reject.

Tested with LÖVE 12.0-development (c4aaab6).


## Usage Example

Only `utf8_check.lua` is required.

```lua
local utf8Check = require("path.to.utf8_check")

local good_str = "foo_bar"
local bad_str = "foo\xC3\000bar"

print(utf8Check.check(good_str))
--> true, nil, nil (good)

print(utf8Check.check(bad_str))
--> false, 4, "Octet #2: Multi-byte code points cannot contain 0 / Nul bytes."
```


# API

## utf8Check.check

Checks a UTF-8 string for encoding errors and invalid code points.

`local ok, pos, err = utf8Check.check(str, i, j)`

* `str`: The UTF-8 string to check.

* `i`: *(1)* The first byte position to check. Range 1 to `max(1, #str)`. The index should point to the first byte of a UTF-8 sequence (and not a continuation byte).

* `j`: *(#str)* The last byte position to check. Range `i` to `max(1, #str)`.

**Returns:** `true` if no problem was found with the string. Otherwise, `false`, the byte position where validation failed, and an error string.


# Options

`utf8Check.check_surrogates`: *(true)* Controls whether surrogate values are checked (and rejected as invalid).


# MIT License

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
