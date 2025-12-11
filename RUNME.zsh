#!/usr/bin/env zsh
./flags.help.sh

# Portable in-place sed (works on macOS and Linux)
sedi() {
    local file="$1"
    shift
    local tmp="${file}.tmp.$$"
    sed "$@" "$file" > "$tmp" && mv "$tmp" "$file"
}

mkdir -p verb/
mlr -l > verbs.list
mlr aux-list | grep '^ ' | sed 's/^ *//' | sed 's/^mlr //' >> verbs.list
cat verbs.list | while read verb; do
    mlr $verb --help > verb/$verb.help
done
# correct some of the aux commands that doesn't have a meaningful --help
echo '{topic} Print help documention.' > verb/help.help
echo 'Print auxiliary functions.' > verb/aux-list.help

# write verb/*.desc
for file in verb/*.help; do
    # Extract description by excluding a Usage line and keeping lines up until options gets listed.
    grep -v '^Usage:' $file | sed -nE '/^Option|options:$|^$|^-/q;p' > $file.desc
done
# fix top's alternative section order
grep -v '^Usage:' verb/top.help | grep -v -- '^[ -]' > verb/top.help.desc

# collect verb/*.desc in descs.help
echo -n > descs.help
for file in verb/*.desc; do
    echo -n "${file:r:r:t}:" >> descs.help
    cat $file | tr '\n' ' ' | sed 's/ $//' >> descs.help
    echo "" >> descs.help
done

# write verb/*.opt
for file in verb/*.help; do
    grep '^ *-' $file | sed 's/^ *//' | sed "s/'/\\\'/g" | sed -E 's/ +/\t/' | sed -E 's/ +/ /g' | ./table_unjag.sh 1 '\t' '|' | sed -E 's/\t(.*)/[\1]/' > $file.opt
done
# make some options complete filenames
for f in verb/*.help.opt; do sedi "$f" '/{.*file.*}/s/$/:filename:_files/'; done
# help doesn't print "this message"
for f in verb/*.opt; do sedi "$f" 's/\[Show this message.\]//'; done

# uniq: -f is a synonym for -g (not listed in --help but documented)
echo '-f[{d,e,f} Synonym for -g.]' >> verb/uniq.help.opt

# sub/gsub/ssub: add positional args for old and new patterns (not listed in --help)
for verb in sub gsub ssub; do
    echo '1:old:' >> verb/$verb.help.opt
    echo '2:new:' >> verb/$verb.help.opt
done

# join: -l and --lk need fields from left file (-f), not main input
# Mark these with special suffix that _mlr.sh will recognize
sedi verb/join.help.opt 's/^-l\[/-l[{left-file-fields} /'
sedi verb/join.help.opt 's/^--lk\[/--lk[{left-file-fields} /'
sedi verb/join.help.opt 's/^--left-keep-field-names\[/--left-keep-field-names[{left-file-fields} /'

# remove help options since we add subcommands specifically for mlr help in _mlr.sh
rm verb/help.help.opt
# list subcommands for mlr help. Added in _mlr.sh
mlr help topics | grep -E 'mlr help [a-z/-]+' -o | uniq | cut -f3 -d' ' > help.topics

./_mlr.sh

