# generate.sh guide

`generate.sh` can directly generate completion scripts for most commands.

However, the help of some commands is not standardized, or some options or positional parameters in the command require dynamic data, you may need to add scripts to assist `generate.sh` to complete the job.

You may check out the [src](https://github.com/sigoden/argc-completions/tree/main/src) for experience.

## processing flow

`generate.sh` internally generates the completion script according to the following processing flow.

```
                        lexer.awk                          parser.awk
help-text(_patch_help) -----------> table(_patch_script) -------------> script
              
```

Let's take `aichat` as an example.

1. help-text: `aichat --help`

```
A powerful chatgpt cli.

Usage: aichat [OPTIONS] [TEXT]...

Arguments:
  [TEXT]...  Input text

Options:
  -m, --model <MODEL>    Choose a model
  -p, --prompt <PROMPT>  Add a GPT prompt
  -H, --no-highlight     Disable syntax highlighting
  -S, --no-stream        No stream output
      --list-roles       List all roles
      --list-models      List all models
  -r, --role <ROLE>      Select a role
      --info             Print system-wide information
      --dry-run          Run in dry run mode
  -h, --help             Print help
  -V, --version          Print version
```

2. table: `aichat --help | awk -f scripts/lexer.awk`

```
option # -m, --model <MODEL> # Choose a model
option # -p, --prompt <PROMPT> # Add a GPT prompt
option # -H, --no-highlight # Disable syntax highlighting
option # -S, --no-stream # No stream output
option # --list-roles # List all roles
option # --list-models # List all models
option # -r, --role <ROLE> # Select a role
option # --info # Print system-wide information
option # --dry-run # Run in dry run mode
option # -h, --help # Print help
option # -V, --version # Print version
argument # [TEXT]... # Input text
```

3. script: `aichat --help | awk -f scripts/lexer.awk | awk -f scripts/parser.awk`

```sh
# @option -m --model         Choose a model
# @option -p --prompt        Add a GPT prompt
# @flag -H --no-highlight    Disable syntax highlighting
# @flag -S --no-stream       No stream output
# @flag --list-roles         List all roles
# @flag --list-models        List all models
# @option -r --role          Select a role
# @flag --info               Print system-wide information
# @flag --dry-run            Run in dry run mode
# @flag -h --help            Print help
# @flag -V --version         Print version
# @arg TEXT*                 Input text
```

## `_patch*` functions 

When `generate.sh <cmd>` is executed, it will look for a `<cmd>.sh` file in the `src/` directory and run the `_patch_*` functions in it.

### `_patch_help`

`_patch_help` is a hook to provide/patch help text. If ommited, `generate.sh` runs `<cmd> <subcmd>... --help` to generate help text.

Here are some use cases for `_patch_help`:

- [curl](https://github.com/sigoden/argc-completions/blob/main/src/curl.sh): execute `curl --help all` to get help text.
- [cargo](https://github.com/sigoden/argc-completions/blob/main/src/cargo.sh): append some subcommands.
- [npm](https://github.com/sigoden/argc-completions/blob/main/src/npm.sh): manually provide help text as the help text generated by npm is too non-standard.
- [yarn](https://github.com/sigoden/argc-completions/blob/main/src/yarn.sh): override all subcommands since yarn's subcommands don't have descriptions, and manually provide help text for some nested subcommands.

### `_patch_table`

`_patch_table` is a hook to patch the generated table，usually used to bind option/positional parameter to `_choice*` functions.

Let's also take `aichat` as an example.

```sh
_patch_table() {
    _patch_util_bind_choice_fn \
        '--model:_choice_model' \
        '--role:_choice_role'
}
```

With `_patch_table`, `_choice_*` is appended to fourth column.

```diff
- option # -m, --model <MODEL> # Choose a model
+ option # -m, --model <MODEL> # Choose a model # [`_choice_model`]
...
- option # -r, --role <ROLE> # Select a role
+ option # -r, --role <ROLE> # Select a role # [`_choice_role`]
```

This affects the final generated argc script.

```diff
- # @option -m --model         Choose a model
+ # @option -m --model[`_choice_model`]    Choose a model
...
- # @option -r --role          Select a role
+ # @option -r --role[`_choice_role`]      Select a role
```

## `_choice*` functions

`_choice_fn` will provide dynamic data.

Let's also take `aichat` as an example.

Suppose you are typing `aichat --role <tab>`, when `<tab>` is pressed, `_choice_role` bound to `--role` will run and provide completion data.

In `_choice*` function, you can use `argc_*` variables to easily access option/positional value.

We also privode some [utility functions](https://github.com/sigoden/argc-completions/blob/main/utils/_argc_utils/) to make it easier to write `_choice*` function.