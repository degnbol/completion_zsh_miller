#!/usr/bin/env zsh
# write _mlr by replacing #FLAGS, #SUBCMDS and #DESCS in _mlr.templ.

# Helper function: print lines from template between markers
# Usage: template_section START_PATTERN END_PATTERN
# Prints lines after START_PATTERN up to (not including) END_PATTERN
# If START_PATTERN is empty, starts from beginning
# If END_PATTERN is empty, goes to end of file
template_section() {
    local start="$1" end="$2"
    if [[ -z "$start" && -n "$end" ]]; then
        # From beginning to end pattern (exclusive)
        sed -n "1,/^${end}/{ /^${end}/d; p; }" _mlr.templ
    elif [[ -n "$start" && -n "$end" ]]; then
        # From start pattern to end pattern (both exclusive)
        sed -n "/^${start}/,/^${end}/{ /^${start}/d; /^${end}/d; p; }" _mlr.templ
    elif [[ -n "$start" && -z "$end" ]]; then
        # From start pattern to end of file (start exclusive)
        sed -n "/^${start}/,\${ /^${start}/d; p; }" _mlr.templ
    fi
}

# Section 1: beginning to #FLAGS
template_section "" "#FLAGS" > _mlr

# ' for some reason can't be escaped in _mlr without breaking things so I remove the one instance ("Don't")
# I also tried using double quotes instead but then things in ticks `` are executed which is a problem as well.
tr -d "'" < flags.help | sed "s/^/'/" | sed "s/$/' \\\/" | sed 's/{/\\{/g' | sed 's/}/\\}/g' >> _mlr

# Section 2: #FLAGS to #SUBCMDS
template_section "#FLAGS" "#SUBCMDS" >> _mlr

for file in verb/*opt; do
    echo "${file:r:r:t})" >> _mlr
    echo '_arguments "${_arguments_options[@]}" \' >> _mlr
    # Process each option line:
    # - Check for field name patterns BEFORE escaping
    # - Escape quotes and braces
    # - Add field completion for flags with field name patterns (but not :filename:_files)
    while IFS= read -r line; do
        # Check patterns BEFORE escaping
        local is_filename=0 is_fieldname=0
        if [[ "$line" == *":filename:_files"* ]]; then
            is_filename=1
        # Only match flags where the description STARTS with field-name indicators
        # e.g. "-f[{a,b,c} ..." or "-g[{comma-separated ..."
        # This avoids matching "-x[... field names specified by -f]"
        elif [[ "$line" =~ ^-[a-zA-Z-]+'\[(\{[a-z],[a-z],[a-z]\}|\{comma-separated|\{one or more comma-separated|Field name)' ]]; then
            is_fieldname=1
        fi

        # Escape special characters using sed (zsh parameter expansion has issues with })
        line=$(echo "$line" | sed 's/"/\\"/g; s/{/\\{/g; s/}/\\}/g')

        # Output with appropriate completion
        if (( is_filename )); then
            echo "\"${line}\" \\"
        elif (( is_fieldname )); then
            # Add + after flag name to indicate it takes an argument
            # -f[desc] becomes -f+[desc]:field:_mlr_field_names
            line=$(echo "$line" | sed 's/^\(-[a-zA-Z-]*\)\[/\1+[/')
            echo "\"${line}:field:_mlr_field_names\" \\"
        else
            echo "\"${line}\" \\"
        fi
    done < "$file" >> _mlr
    # complete filename or chain keyword (then/+) at the end of each subcmd (verb).
    echo '"*:filename or chain:_mlr_files_or_chain" \' >> _mlr
    echo '&& ret=0\n;;' >> _mlr
done

# add help topics from file help.topics
echo 'help)
_arguments -C "1: :->cmds"
case "$state" in
    cmds)
        _values "mlr_help command" \' >> _mlr
sed 's/^/"/' help.topics | sed 's/$/" \\/' >> _mlr
echo '        ;;
esac
;;' >> _mlr

# Section 3: #SUBCMDS to #DESCS
template_section "#SUBCMDS" "#DESCS" >> _mlr

# add verb descriptions (escape backticks to prevent command substitution)
sed 's/"/\\"/g' descs.help | sed 's/`/\\`/g' | sed 's/^/"/' | sed 's/$/" \\/' >> _mlr

# Section 4: #DESCS to end
template_section "#DESCS" "" >> _mlr

