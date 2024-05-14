#!/bin/bash

# set -x

# Subshell can make sure variables defined can only live during the script exec
(
    # Function to check file type based on file extension
    check_file_type() {
        filename="$1"
        case "$filename" in
            *.txt) echo "Reading $filename" ;;
            *) 
                echo "No support for file extension other than txt." 
                echo "Each extention has its own interpretation for escape character."
                exit 1
                ;;
        esac
    }

    # Read configuration values from JSON file
    read_config() {
        config_file="$1"

        # Check if config file exists
        if [ ! -f "$config_file" ]; then
            echo "Error: Config file '$config_file' not found."
            exit 1
        fi

        # Read JSON file and parse values
        while IFS= read -r line; do
            # Parse JSON key-value pairs
            name=$(echo "$line" | jq -r '.name')
            column=$(echo "$line" | jq -r '.column')
            row=$(echo "$line" | jq -r '.row')
            color=$(echo "$line" | jq -r '.color')
            regex=$(echo "$line" | jq -r '.regex')
            output=$(echo "$line" | jq -r '.output')
            
            # Store values in associative arrays
            names+=("$name")
            columns+=("$column")
            rows+=("$row")
            colors+=("$color")
            regexs+=("$regex")
            outputs+=("$output")
        done < <(jq -c '.[]' "$config_file")
    }

    # Function to preprocess the input string
    preprocess_input() {
        input_string="$1"

        # Truncate variable width spaces to two spaces
        processed_string=$(echo "$input_string" | sed 's/ \{2,\}/  /g')

        echo "$processed_string"
    }

    initialize_file() {
        for out in "${outputs[@]}"; do
            # Create the file if it doesn't exist
            touch "$out"
            # Truncate the file to remove its contents
            : > "$out"
        done
    }

    # Function to extract values
    extract_values() {
        input_string="$1"

        # Loop through configuration arrays
        for ((i = 0; i < ${#names[@]}; i++)); do
            name="${names[$i]}"
            column="${columns[$i]}"
            row="${rows[$i]}"
            color="${colors[$i]}"
            regex="${regexs[$i]}"
            output="${outputs[$i]}"
            
            # Construct pattern using configuration values
            if (( color < 0 ));then
                pattern="^[[${column};${row}H"
                # Use awk to extract values between the patterns
                mawk -v pattern="$pattern" '{
                    while (match($0, "\\^\\[\\['"$column"';'"$row"'H" "  '"$regex"'\\^\\[\\[")) {
                        value = substr($0, RSTART + length(pattern), RLENGTH - length(pattern) - 3); 
                        gsub(",", "", value); # Remove commas from the value
                        print value >> "'"$output"'"; 
                        $0 = substr($0, RSTART + RLENGTH)
                    } 
                }' <<< "$input_string"
                
                pattern="^[[K^[[${column};${row}H"
                mawk -v pattern="$pattern" '{
                    while (match($0, "\\^\\[\\[K\\^\\[\\['"$column"';'"$row"'H" "  '"$regex"'\\^\\[\\[")) {
                        value = substr($0, RSTART + length(pattern), RLENGTH - length(pattern) - 3); 
                        gsub(",", "", value); # Remove commas from the value
                        print value >> "'"$output"'"; 
                        $0 = substr($0, RSTART + RLENGTH)
                    } 
                }' <<< "$input_string"
            else
                pattern="^[[0;${color}m^[[${column};${row}H"
                # Use awk to extract values between the patterns
                mawk -v pattern="$pattern" '{
                    while (match($0, "\\^\\[\\[0;'"$color"'m\\^\\[\\['"$column"';'"$row"'H" "  '"$regex"'\\^\\[\\[")) {
                        value = substr($0, RSTART + length(pattern), RLENGTH - length(pattern) - 3); 
                        gsub(",", "", value); # Remove commas from the value
                        print value >> "'"$output"'"; 
                        $0 = substr($0, RSTART + RLENGTH)
                    } 
                }' <<< "$input_string"

                pattern="^[[K^[[0;${color}m^[[${column};${row}H"
                # Use awk to extract values between the patterns
                mawk -v pattern="$pattern" '{
                    while (match($0, "\\^\\[\\[K\\^\\[\\[0;'"$color"'m\\^\\[\\['"$column"';'"$row"'H" "  '"$regex"'\\^\\[\\[")) {
                        value = substr($0, RSTART + length(pattern), RLENGTH - length(pattern) - 3); 
                        gsub(",", "", value); # Remove commas from the value
                        print value >> "'"$output"'"; 
                        $0 = substr($0, RSTART + RLENGTH)
                    } 
                }' <<< "$input_string"
            fi


            
        done

    }

    # Main function
    main() {
        config_file="config.json"

        declare -a names columns rows colors regexs outputs
        read_config "$config_file"

        mkdir -p ../res

        # Check if input file is provided
        if [ $# -ne 1 ]; then
            echo "Usage: $0 <input_file>"
            exit 1
        fi

        initialize_file

        input_file="$1"

        # Check if input file exists
        if [ ! -f "$input_file" ]; then
            echo "Error: Input file '$input_file' not found."
            exit 1
        fi

        # Check if config file exists
        if [ ! -f "$config_file" ]; then
            echo "Error: Config file '$config_file' not found."
            exit 1
        fi

        check_file_type "$input_file"

        # Read input file and preprocess each line
        cat -v "$input_file" | while IFS= read -r line; do
            processed_line=$(preprocess_input "$line")
            extract_values "$processed_line"
        done
    }

    # Call main function with command line arguments
    main "$@"
)
