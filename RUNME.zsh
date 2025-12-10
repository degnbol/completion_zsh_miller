#!/usr/bin/env zsh
./flags.help.sh

mkdir -p verb/
mlr -l > verbs.list
mlr aux-list | grep '^ ' | sed 's/^ *//' >> verbs.list
cat verbs.list | while read verb; do
    mlr $verb --help > verb/$verb.help
done
# correct some of the aux commands that doesn't have a meaningful --help
echo '{topic} Print help documention.' > verb/help.help
echo 'Print auxiliary functions.' > verb/aux-list.help

# write verb/*.desc
for file in verb/*.help; do
    grep -v '^Usage:' $file | ./text_grep.py --stop "^Option|options:$|^$|^-" > $file.desc
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
sed -i '' '/{.*file.*}/s/$/:filename:_files/' verb/*.help.opt
# help doesn't print "this message"
sed -i '' 's/\[Show this message.\]//' verb/*.opt

# remove help options since we add subcommands specifically for mlr help in _mlr.sh
rm verb/help.help.opt
# list subcommands for mlr help. Added in _mlr.sh
mlr help topics | grep -E 'mlr help [a-z/-]+' -o | uniq | cut -f3 -d' ' > help.topics

./_mlr.sh

