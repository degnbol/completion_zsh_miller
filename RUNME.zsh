#!/usr/bin/env zsh
cd ${0:A:h}

# Record the mlr version this data was generated against (drift detection).
mlr --version > VERSION

src/flags.help.sh > data/flags.help

# Portable in-place sed (works on macOS and Linux)
sedi() {
    local file="$1"
    shift
    local tmp="${file}.tmp.$$"
    sed "$@" "$file" > "$tmp" && mv "$tmp" "$file"
}

mkdir -p data/verb/
src/verbs.list.sh > data/verbs.list
cat data/verbs.list | while read verb; do
    mlr $verb --help > data/verb/$verb.help
done
# correct some of the aux commands that doesn't have a meaningful --help
echo '{topic} Print help documention.' > data/verb/help.help
echo 'Print auxiliary functions.' > data/verb/aux-list.help

# write data/verb/*.desc
for file in data/verb/*.help; do
    # Extract description by excluding a Usage line and keeping lines up until options gets listed.
    grep -v '^Usage:' $file | sed -nE '/^Option|options:$|^$|^-/q;p' > $file.desc
done
# fix top's alternative section order
grep -v '^Usage:' data/verb/top.help | grep -v -- '^[ -]' > data/verb/top.help.desc

# collect data/verb/*.desc in data/descs.help
echo -n > data/descs.help
for file in data/verb/*.desc; do
    echo -n "${file:r:r:t}:" >> data/descs.help
    cat $file | tr '\n' ' ' | sed 's/ $//' >> data/descs.help
    echo "" >> data/descs.help
done

# write data/verb/*.opt
for file in data/verb/*.help; do
    grep '^ *-' $file | sed 's/^ *//' | sed "s/'/\\\'/g" | sed -E 's/ +/\t/' | sed -E 's/ +/ /g' | src/table_unjag.sh 1 '\t' '|' | sed -E 's/\t(.*)/[\1]/' > $file.opt
done
# make some options complete filenames
for f in data/verb/*.help.opt; do sedi "$f" '/{.*file.*}/s/$/:filename:_files/'; done
# help doesn't print "this message"
for f in data/verb/*.opt; do sedi "$f" 's/\[Show this message.\]//'; done

# uniq: -f is a synonym for -g (not listed in --help but documented)
echo '-f[{d,e,f} Synonym for -g.]' >> data/verb/uniq.help.opt

# sub/gsub/ssub: add positional args for old and new patterns (not listed in --help)
for verb in sub gsub ssub; do
    echo '1:old:' >> data/verb/$verb.help.opt
    echo '2:new:' >> data/verb/$verb.help.opt
done

# rename: positional arg is old1,new1,old2,new2,... - complete old names from input file
echo '1:old,new pairs:_mlr_rename_field_names' >> data/verb/rename.help.opt

# join: -l and --lk need fields from left file (-f), not main input
# Mark these with special suffix that _mlr.sh will recognize
sedi data/verb/join.help.opt 's/^-l\[/-l[{left-file-fields} /'
sedi data/verb/join.help.opt 's/^--lk\[/--lk[{left-file-fields} /'
sedi data/verb/join.help.opt 's/^--left-keep-field-names\[/--left-keep-field-names[{left-file-fields} /'

# remove help options since we add subcommands specifically for mlr help in _mlr.sh
rm data/verb/help.help.opt
# list subcommands for mlr help. Added in _mlr.sh
mlr help topics | grep -E 'mlr help [a-z/-]+' -o | uniq | cut -f3 -d' ' > data/help.topics

src/_mlr.sh
