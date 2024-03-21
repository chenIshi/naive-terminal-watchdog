#!/bin/bash

# Function to preprocess the input string
preprocess_input() {
    input_string="$1"

    # Truncate variable width spaces to two spaces
    processed_string=$(echo "$input_string" | sed 's/ \{2,\}/  /g')

    echo "$processed_string"
}

# Function to extract values
extract_values() {
    input_string="$1"

    # Use awk to extract values between the patterns
    awk '{
        while (match($0, /\^\[\[5;22H  ([0-9,]*)\^\[\[/)) {
            value = substr($0, RSTART + 10, RLENGTH - 14); 
            print value; 
            $0 = substr($0, RSTART + RLENGTH)
        } 
    }' <<< "$input_string"
}

# Main function
main() {
    # Check if input file is provided
    if [ $# -ne 1 ]; then
        echo "Usage: $0 <input_file>"
        exit 1
    fi

    input_file="$1"

    # Check if input file exists
    if [ ! -f "$input_file" ]; then
        echo "Error: Input file '$input_file' not found."
        exit 1
    fi

    # Read input file and preprocess each line
    cat -v "$input_file" | while IFS= read -r line; do
        processed_line=$(preprocess_input "$line")
        extract_values "$processed_line"
    done
}

# Call main function with command line arguments
main "$@"
