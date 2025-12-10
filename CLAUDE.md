# Miller Zsh Completion

This directory contains zsh completion for [Miller (mlr)](https://miller.readthedocs.io/).

## Running Tests

```bash
./test/run_tests.zsh
```

## File Structure

- `_mlr` - Generated completion file (do not edit directly)
- `_mlr.templ` - Template for generating `_mlr`
- `_mlr.sh` - Script that generates `_mlr` from template and help files
- `flags.help` - Generated file containing main mlr flags
- `flags.help.sh` - Script that generates `flags.help` from `mlr help flags`
- `verb/` - Directory containing verb-specific options (*.opt files)
- `descs.help` - Verb descriptions
- `verbs.list` - List of verbs
- `help.topics` - Help topic completions
- `table_unjag.sh` - Helper script for parsing help output
- `RUNME.zsh` - Script to regenerate everything
- `test/` - Test suite

## Regenerating Completions

```bash
./RUNME.zsh
# Or manually:
./flags.help.sh  # Regenerate flags.help
./_mlr.sh        # Regenerate _mlr
```

After regenerating, reload in zsh:
```bash
unfunction _mlr 2>/dev/null; rm -f ~/.zcompdump* && exec zsh
```

## Architecture

### Template (`_mlr.templ`)

The template contains:
1. Main `_mlr()` function with `_arguments` call for global flags
2. State handlers (`from_file`, `mlr-tui`) for special completions
3. Helper functions: `_mlr_commands`, `_mlr_files_or_chain`, `_mlr_field_names`

Placeholders replaced by `_mlr.sh`:
- `#FLAGS` - Main mlr flags from `flags.help`
- `#SUBCMDS` - Verb-specific option handling from `verb/*.opt`
- `#DESCS` - Verb descriptions from `descs.help`

### Key Design Decisions

**`_arguments_options=(-S -C)`**
- `-S`: Don't complete options after `--`
- `-C`: Modify curcontext for state actions
- Note: `-s` (option stacking) was intentionally removed as it causes cursor positioning issues

**State-based file completion for `--from`**
```zsh
'--from[...]: :->from_file'
# Instead of:
'--from[...]:filename:_files'
```
Using `_alternative 'files:filename:_files'` in a state handler enables proper substring matching (e.g., `tion.zsh` -> `completion.zsh`). Direct `_files` in `_arguments` doesn't respect the global `matcher-list`.

**Early return for option completion**
```zsh
[[ -z "$line" && "$state" == "mlr-tui" ]] && return ret
```
When completing main flags (before any verb), `$line` is empty. Without this check, the `mlr-tui` state handler runs and manipulates `words`/`CURRENT`, causing cursor positioning issues. The condition also checks for `mlr-tui` state specifically so other states like `from_file` still work.

### Verb Chaining

Miller supports verb chaining with `then` or `+`:
```bash
mlr --csv head -n 5 then cut -f name then sort file.csv
```

The `mlr-tui` state handler detects chain delimiters and resets completion context for each verb segment.

### Field Name Completion

`_mlr_field_names` reads the input file (from `--from` or trailing args), extracts column names using `mlr --ojsonl head -n 1 | jq -r 'keys[]'`, and offers them as completions for flags like `-f`, `-g`.

## Zsh Completion Concepts

### Matcher List (in `~/dotfiles/zsh/completion.zsh`)

```zsh
zstyle ':completion:*' matcher-list \
    'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' \
    'r:|[._-]=* r:|=*' \
    'l:|=* r:|=*'
```
- Case-insensitive matching
- Partial matching at separators
- Substring matching anywhere

### Completer Chain

```zsh
zstyle ':completion:*' completer _expand _complete _match
```
- `_approximate` was removed to prevent typo-tolerant matches (e.g., `--cs` matching `--asv` instead of `--csv`)

## Troubleshooting

**Completion not updating after changes:**
```bash
unfunction _mlr 2>/dev/null; rm -f ~/.zcompdump* && exec zsh
```

**Debug completion state:**
```zsh
echo "state='$state' line='$line' words='$words' CURRENT=$CURRENT" >> /tmp/debug.txt
```

**Test minimal completion:**
```zsh
unfunction _mlr 2>/dev/null
_mlr() {
    _arguments -S -C \
        '--csv[desc]' \
        '--asv[desc]' \
        && return 0
}
mlr --cs<TAB>
```
