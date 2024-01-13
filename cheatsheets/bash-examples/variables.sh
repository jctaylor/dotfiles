var="one two one three"

# Replace first "one" with "five"
echo "${var/one/five}"
# Output: five two one three

# Replace all "one" with "five"
echo "${var//one/five}"
# Output: five two five three

# The pattern can be assigned to a new variable or reassigned to the original
newvar="${var//one/five}"
echo "$newvar"
# Output: five two five three

