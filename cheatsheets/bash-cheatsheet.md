# bash Cheat Sheet


## test conditions

-a <filename>   -- filename exists
-f <filename>   -- filename exists and is a regular file
-d <filename>   -- filename exists and is a directory
-s <filename>   -- filename exists and has a size > 0
-z $some_string -- $some_string has 0 characters (i.e. is empty)
-n $some_string -- $some_string has more than 0 characters
$string_a == $string_b - true if $string_a is equal to $string_b
$string_a != $string_b - true if $string_a is not equal to $string_b
$x -eq $y - true if integer $x is equal to integer $y
$x -lt $y - true if integer $x is less than integer $y
$x -gt $y - true if integer $x is greater than integer $y

```bash
if [[ $num -eq 42 ]]; then    ## ALSO [[ $num -eq ]]
  echo 'num is actually equal to 42'
else # else branch
  echo 'num is not 42'
fi
```

## string manipulation

### default values

```bash
str1="Hello"
str2="World"
# str3 is unset
echo ${str1-Hi}  # Hello
echo ${str3-You} # You   Does not set str3
```

```bash
str1="Hello"
str2="World"
# str3 is unset
echo ${str1=Hi}  # Hello
echo ${str3=You} # You   and leaves str3=You
echo ${str3}
```

```bash
#error if value not se
param1="P1 is set"
param2=""   # set but null
# param3 is not set
echo ${param1?"Error not set1"}  #  OK "P1 is set"
echo ${param2?"Error not set1"}  #  OK ""
echo ${param3?"Error not set1"}  #  ERROR  exit 1


### string length
```bash
${#str}
`expr length ${str}
`expr "$str" : '.*'`
```

### string indexing
```bash
str=01234abcdef
${str:3:5}  # from index 3 to 3+5 = 345ab

# right indexing too, but the negative sign must be distiguished
${str:-4}  # 012345abcdef  ( or 4 if "$str" = "" i.e. default )
```

## Replacement
```bash
str1="The 1st car is blue, and the 2nd car is blue"
echo ${str1/blue/red}    # The 1st car is red, and the 2nd car is blue
echo ${str1//blue/grey}  # The 1st car is grey, and the 2nd car is grey
```

```bash
# Replace whole string if prefix matches
cc="gcc-v2.0"
echo ${cc/#gcc/clang}     # clang
echo ${cc/#gcc-v3/clang}  # gcc-v2.0
```

## Indirect references

```bash
# Expand a variable and use it as a variable name to further expand
str1="This is the string"
str2="Another string"
varName=str1
echo ${!varName}  # "This is the string"
echo ${!str*}     # str1 str2
```

### Array indexing

```bash
myArr=( ZERO one 2 three 4 b b b )
echo ${myArr[@]:3:2}  # three 4
```

## References

[ABS](https://tldp.org/LDP/abs/html/index.html)
[string manipulation](https://tldp.org/LDP/abs/html/string-manipulation.html)


