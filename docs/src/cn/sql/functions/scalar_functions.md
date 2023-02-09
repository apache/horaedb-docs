# Scalar Functions

CeresDB SQL基于 [DataFusion](https://github.com/CeresDB/arrow-datafusion) 实现，支持的标量函数如下。更多详情请参考： [Datafusion](https://github.com/CeresDB/arrow-datafusion/blob/master/docs/source/user-guide/sql/scalar_functions.md)

## Math Functions

| Function              | Description |
|-----------------------|----------|
| abs(x)                |absolute value|
| acos(x)               |inverse cosine|
| asin(x)               |inverse sine|
| atan(x)               |inverse tangent|
| atan2(y, x)           |inverse tangent of y / x|
| ceil(x)               |nearest integer greater than or equal to argument|
| cos(x)                |cosine|
| exp(x)                |exponential|
| floor(x)              |nearest integer less than or equal to argument|
| ln(x)                 |natural logarithm|
| log10(x)              |base 10 logarithm|
| log2(x)               |base 2 logarithm|
| power(base, exponent) |base raised to the power of exponent|
| round(x)              |round to nearest integer|
| signum(x)             |sign of the argument (-1, 0, +1)|
| sin(x)                |sine|
| sqrt(x)               |square root|
| tan(x)                |tangent|
| trunc(x)              |truncate toward zero|

## Conditional Functions

| Function | Description                                                                                                                                                                                              |
|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|coalesce| Returns the first of its arguments that is not null. Null is returned only if all arguments are null. It is often used to substitute a default value for null values when data is retrieved for display. |
|nullif| Returns a null value if value1 equals value2; otherwise it returns value1. This can be used to perform the inverse operation of the coalesce expression.|

## String Functions

| Function         | Description                                                                                                                                                                                              |
|------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| ascii            |Returns the number code that represents the specific character.|
| bit_length       |Returns the number of bits in a character string expression.|
| btrim            |Removes the longest string containing any of the characters in characters from the start and end of string.|
| char_length      |Equivalent to length.|
| character_length |Equivalent to length.|
| concat           |Concatenates two or more strings into one string.|
| concat_ws        |Combines two values with a given separator.|
| chr              |Returns the character based on the number code.|
| initcap          |Capitalizes the first letter of each word in a string.|
| left             |Returns the specified leftmost characters of a string.|
| length           |Returns the number of characters in a string.|
| lower            |Converts all characters in a string to their lower case equivalent.|
| lpad             |Left-pads a string to a given length with a specific set of characters.|
| ltrim            |Removes the longest string containing any of the characters in characters from the start of string.|
| md5              |Calculates the MD5 hash of a given string.|
| octet_length     |Equivalent to length.|
| repeat           |Returns a string consisting of the input string repeated a specified number of times.|
| replace          |Replaces all occurrences in a string of a substring with a new substring.|
| reverse          |Reverses a string.|
| right            |Returns the specified rightmost characters of a string.|
| rpad             |Right-pads a string to a given length with a specific set of characters.|
| rtrim            |Removes the longest string containing any of the characters in characters from the end of string.|
| digest           |Calculates the hash of a given string.|
| split_part       |Splits a string on a specified delimiter and returns the specified field from the resulting array.|
| starts_with      |Checks whether a string starts with a particular substring.|
| strpos           |Searches a string for a specific substring and returns its position.|
| substr           |Extracts a substring of a string.|
| translate        |Translates one set of characters into another.|
| trim             |Removes the longest string containing any of the characters in characters from either the start or end of string.|
| upper            |Converts all characters in a string to their upper case equivalent.|


## Regular Expression Functions

| Function       | Description                                                                                                                                                                                              |
|----------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| regexp_match   |Determines whether a string matches a regular expression pattern.|
| regexp_replace |Replaces all occurrences in a string of a substring that matches a regular expression pattern with a new substring.|

## Temporal Functions

| Function             | Description                                                                                                                                                                                              |
|----------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| to_timestamp         |Converts a string to type Timestamp(Nanoseconds, None).|
| to_timestamp_millis  |Converts a string to type Timestamp(Milliseconds, None).|
| to_timestamp_micros  |Converts a string to type Timestamp(Microseconds, None).|
| to_timestamp_seconds |Converts a string to type Timestamp(Seconds, None).|
| extract              |Retrieves subfields such as year or hour from date/time values.|
| date_part            |Retrieves subfield from date/time values.|
| date_trunc           |Truncates date/time values to specified precision.|
| date_bin             |Bin date/time values to specified precision.|
| from_unixtime        |Converts Unix epoch to type Timestamp(Nanoseconds, None).|
| now                  |Returns current time as Timestamp(Nanoseconds, UTC).|

see more detail in [DataFusion](https://github.com/CeresDB/arrow-datafusion/blob/master/docs/source/user-guide/sql/scalar_functions.md)

## Other Functions

| Function     | Description              |
|--------------|--------------------------|
| array        | Create an array.         |
| arrow_typeof | Returns underlying type. |
| in_list      | Check if value in list.  |
| random       | Generate random value.   |
| sha224       | sha224                   |
| sha256       | sha256                   |
| sha384       | sha384                   |
| sha512       | sha512                   |
| struct       | Create struct.           |
| to_hex       | Convert to hex.          |



### `array`

### `arrow_typeof`

Returns the underlying Arrow type of the the expression:


### `in_list`

### `random`

### `sha224`

### `sha256`

### `sha384`

### `sha512`

### `struct`

### `to_hex`