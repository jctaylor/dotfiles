
## Use mapfile to append to an array
# Initialize an existing array (optional, but shows the append behavior)
declare -a my_array=("item1" "item2")

# Append new lines to the array using mapfile and process substitution
# -t removes trailing newlines from each line read
# -O "${#my_array[@]}" sets the starting index to the current length
mapfile -t -O "${#my_array[@]}" my_array < <(
    echo "item3"
    echo "item4"
)

# Print all elements of the array
for item in "${my_array[@]}"; do
    echo "$item"
done

