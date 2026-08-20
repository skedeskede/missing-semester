# Lecture 2 — Shell Tools and Scripting (2020 edition)

Repo path: `2020/02-shell-tools/`

---

## Notes — vocabulary I was missing

The notes read as impenetrable on first pass because of density, not difficulty.
This block from the lecture packs eight unfamiliar tokens into four lines:

```bash
echo "Running program $0 with $# arguments with pid $$"
for file in "$@"; do
    grep foobar "$file" > /dev/null 2> /dev/null
    if [[ $? -ne 0 ]]; then
```

None of them can be derived by thinking harder — they are conventions. The list,
with the names to look them up by:

| Token | Name | Meaning |
|---|---|---|
| `$0` | special parameter | name the program was invoked as |
| `$#` | special parameter | number of arguments |
| `$$` | special parameter | process ID of the current shell |
| `$@` | special parameter | all arguments, as separate words |
| `$?` | special parameter | exit status of the last command |
| `[[ ]]` | conditional expression | test construct; returns an exit status |
| `2>` | redirection | send file descriptor 2 (stderr) somewhere |
| `/dev/null` | the null device | discards everything written to it |

`man bash`, sections **Special Parameters**, **Conditional Expressions**,
**Redirection**. Short lists, and between them they are most of the vocabulary
that makes shell scripts look unreadable.

**Method that fixes this:** don't read the script, run the pieces. `echo $$` in a
terminal answers the question in one second. A shell script isn't a proof — there
is nothing to hold in your head, because the shell will just tell you.

### `/dev/null`

`/dev/null` is sort of the garbage bin of programs. Output wasn't being *printed*
there — the code took both the output and the error output of the program and
redirected them to `/dev/null`, effectively discarding both.

Two separate redirects doing this, not one: `>` catches stdout, `2>` catches
stderr. Different streams, discarded for different reasons — the matched lines in
one case, complaints like "No such file or directory" in the other.

### Exit status, and grep as a predicate

Every command hands the shell a small integer when it exits, called its **exit
status** or return code. The convention is inverted relative to Python or R:
**0 means success, non-zero means failure.**

`grep` here is being used as a **predicate** — a test returning true/false —
rather than as a printer. Its normal output is discarded precisely because only
the status is wanted. Grep distinguishes three cases:

- `0` — a match was found
- `1` — no lines matched
- `2` — something actually went wrong (e.g. the file doesn't exist)

Exiting 1 is not an error. It is an answer. Using exit status to carry a *result*
rather than a *failure* is normal in shell and is what makes this idiom work.

### The bug in the lecture's script

`[[ $? -ne 0 ]]` is true for both 1 and 2. The script cannot tell "no match" from
"no such file", and `>>` creates a file that doesn't exist. So handing it a typo'd
filename silently manufactures a file containing `# foobar`.

General shape: **conflating distinct exit statuses**. Fix by testing the specific
status you mean.

### `$?` is fragile

`$?` is overwritten by *every* command, including an `echo` added while debugging.
Insert one line between the command and the test and `$?` now reports the echo,
which is almost always 0, and the branch silently stops firing.

Habit: capture immediately — `status=$?` on the line directly after the command,
then test `$status`.

### Shorter form

This pattern is common enough that bash has a shortcut: `if grep -q foobar
"$file"; then`. `-q` is grep's quiet flag. The lecture uses the long form because
`$?` is the thing being taught; the long form is what you'll read in other
people's scripts.

### Pattern

`grep` takes a **regular expression** — a small language for describing sets of
strings, not a literal string. `foobar` is a valid regex that happens to match
only the literal text `foobar`; `fo*bar` and `^foo` match many things. Covered
properly in lecture 4 (Data Wrangling). `man grep`, section **REGULAR
EXPRESSIONS**.

---

## Reference — bash syntax

Written up because the syntax felt needlessly complicated compared to Python and
C++, where the space next to `=` doesn't matter and variables don't need sigils.
It isn't arbitrary. It all follows from one design decision.

### The one idea

**Bash is a text-substitution language, not an expression language.**

Python and C++ parse expressions. `x = 5` — the parser knows `x` is a name and `5`
a value, because the grammar says so.

Bash has no expressions. Its entire job is to build command lines. Every line is:
split into words, expand the words, then treat word one as a command and the rest
as its arguments. Everything is a string, because everything ends up as an
argument to a program.

Every oddity below follows from that.

### Why `=` must be glued

A word of the shape `name=value`, appearing before the command, is recognised as
an assignment. Its *shape* is what makes it one.

Glued `=` assigns a value to the variable named before the `=`. Separated, the
name before the `=` is read as a command. Bash isn't being pedantic — with spaces
there is nothing left to distinguish an assignment from a command call.

### Why `$` is required

Bare words are literal text. `cd workdir` passes the six characters `workdir`,
because that's what you want 95% of the time you type a command. Bash can't guess
you meant a variable, since variables and strings are the same type. `$` is the
explicit instruction: **expand this**.

### Why quotes — expansion order

Bash processes a line in fixed stages. Simplified:

1. Split the raw line into words on whitespace
2. Perform expansions — `$var`, `$(cmd)`, `$((math))`, `~`, `{a,b}`
3. **Split the results of step 2 again**, on whitespace
4. Filename expansion — `*`, `?` become matching filenames
5. Remove quotes
6. Word one is the command; the rest are arguments

Step 3 is the trap. Splitting happens *after* substitution, so a variable
containing `My Documents` becomes two arguments. The variable held one string; the
command received two. The name for step 3 is **word splitting**; the whitespace it
splits on is configurable via `IFS` (internal field separator).

Quoting an expansion — `"$workdir"` — skips steps 3 and 4. That is all quotes do
here: suppress re-splitting and globbing.

**`$` and quotes do different jobs.** `$` turns a name into its value; without it
no expansion happens at all. Quotes do nothing to make something a variable — they
protect the *result* from being re-split. `cd $workdir` works fine until the path
contains a space.

**Operational rule:** quote every expansion unless you specifically want it split.
`"$var"`, `"$(cmd)"`, `"$@"`. Not style — the unquoted form is a different
operation.

### The sigils

| Syntax | Name | Does |
|---|---|---|
| `$name` | parameter expansion | value of a variable |
| `${name}` | same, braced | disambiguates: `${file}_old` |
| `$(cmd)` | command substitution | run `cmd`, substitute its stdout |
| `$((expr))` | arithmetic expansion | evaluate integers: `$((n+1))` |
| `$?`, `$@`, `$#` | special parameters | exit status, all args, arg count |
| `[[ ... ]]` | conditional expression | test; returns an exit status |
| `( ... )` | subshell | run in a child process |
| `{ ... ; }` | group | run in the current shell |

### Is it needlessly complicated?

Partly historical accident, partly not. The core design is coherent for what bash
optimises: typing commands interactively. `ls *.txt` and `cd Downloads` work
unquoted, which is thousands of keystrokes saved. The bill comes due in scripts,
where the same defaults become footguns.

Genuinely bad: `[` versus `[[`, `test`'s operator zoo, three quoting styles with
different rules. Those are accreted, not designed.

Practical stance: write shell for what it's good at — gluing programs together,
ten lines or fewer — and reach for Python past that. Run `shellcheck` as a
standing habit.

---

## Reference — redirection and pipes

Rests on one fact: every process starts with three numbered channels, called
**file descriptors**. 0 = stdin, 1 = stdout, 2 = stderr. A program doesn't know
where they point. It writes to 1 and something catches it — the terminal, a file,
another program.

Redirection is the shell rewiring those channels *before* the program starts. The
model: **you are not passing filenames, you are attaching pipes to sockets on the
process.**

### Operators

| Syntax | Name | Effect |
|---|---|---|
| `> file` | output redirect | stdout to `file`, **truncating it to zero first** |
| `>> file` | append redirect | stdout to `file`, appending |
| `< file` | input redirect | `file` becomes stdin |
| `2> file` | fd-specific redirect | stderr to `file` |
| `2>&1` | fd duplication | stderr goes wherever stdout currently goes |
| `&> file` | both (bash) | stdout and stderr to `file` |
| `cmd1 \| cmd2` | pipe | cmd1's stdout becomes cmd2's stdin |

A bare `>` means `1>`. The digit is optional only for 1.

### The truncation trap

`>` empties the file the instant the command starts, before any output arrives. So
`sort file > file` produces an empty file: the shell truncates, then `sort` opens
it and finds nothing. Write to a temporary and move it.

`>>` never truncates.

### Order matters with `2>&1`

`2>&1` means "make fd 2 point where fd 1 points **right now**". It copies the
current target; it doesn't create a link.

- `cmd > file 2>&1` — stdout to file, then stderr copies that. Both in file.
- `cmd 2>&1 > file` — stderr copies stdout's current target (the terminal), then
  stdout moves to the file. Errors still on screen.

Same tokens, different result. Read left to right, tracking where each fd points
after each step. This is why the lecture writes `> /dev/null 2> /dev/null` — two
independent redirects, no ordering question.

### Pipes

`|` connects one process's stdout to the next's stdin, and both run
**concurrently** — not sequentially. `cmd1` doesn't finish and hand over a file;
both run at once with data flowing between them. That's why `yes | head -3`
terminates instead of filling the disk.

Two consequences:

- **Pipes carry stdout only.** Errors from `cmd1` go to the terminal, not into
  `cmd2`. Use `2>&1 |` or bash's `|&` to include them.
- **A pipeline's exit status is the last command's.** `false | true` succeeds.
  `set -o pipefail` makes the pipeline fail if any stage does;
  `${PIPESTATUS[@]}` holds each stage's status individually.

### `<` versus an argument

- `sort file` — `sort` opens the file itself, and knows its name.
- `sort < file` — the shell opens it and hands `sort` an anonymous stream on fd 0.
  `sort` doesn't know a file exists.

Usually identical output. Not always. See the open question at the bottom.

### Others

- `<<< "text"` — **here-string**, feeds a literal string as stdin.
- `<< EOF ... EOF` — **heredoc**, feeds a multi-line block as stdin. Common for
  SQL and config.

### Seen in this lecture

| Line | What it is |
|---|---|
| `pwd > /tmp/workdir.txt` | truncate and write |
| `grep foobar "$file" > /dev/null 2> /dev/null` | discard both streams, keep only the exit status |
| `ls --color=always -a -l / \| cat -v` | bisect the pipeline to inspect what the producer emits |
| `workdir=$(cat /tmp/workdir.txt)` | **not** redirection — command substitution captures output into a variable |

That last row is worth separating. Command substitution captures output into a
variable; redirection moves streams between processes and files. Different
mechanisms, easy to conflate.

---

## Exercise 1 — `ls`

Requirements: all files including hidden, long format, human-readable sizes,
sorted by recency, colorised.

```bash
ls --color=always -a -h -t -l
```

### `--color=always` needs the `=`

`--color`'s argument is *optional*, and GNU's parser can't tell an optional
argument from the next operand across a space. `ls --color always` reads `always`
as a filename — hence `cannot access 'always'`. Options with mandatory arguments
(`--width 80`) accept either form. Since you can't tell which is which without
checking, **use `=` on long options by default**.

### `always` vs `auto`

Three values: `always`, `never`, `auto`. `auto` colorises only when stdout is a
terminal. `always` emits the codes even when piped, so `ls --color=always | grep
foo` sends escape sequences into grep.

The exercise asks for colorised output, so `always` is right here. In a shell
alias, write `auto`.

The underlying behaviour — a program acting differently depending on whether its
output is a terminal or a pipe — is called **TTY detection** (`isatty`). `less`,
`grep` and `git` all do it. It's why piping something sometimes changes its output
format seemingly at random.

### `-h` needs `-l`

`-h` produces `2.8M`, `4.0K`, `16K` instead of `2871424` and `4096`. It only shows
in long format, because short format prints no sizes at all.

### The colour that looked broken

The colour actually worked. It looked like it didn't for two reasons: copying the
output to paste it strips the escape codes, and the `/` listing is almost entirely
directories, so nearly every entry was the same blue and read as uniform.

Colour in a terminal isn't a property of text. It's **ANSI escape sequences** —
invisible control characters embedded in the output stream, which the terminal
interprets as "switch to blue now".

The diagnosis, which is the transferable part:

**First we run `echo $LS_COLORS`.** This ensures that the configuration of colours
when the flag `--color` is added to `ls` is set up correctly. `LS_COLORS` is the
mapping from file type to ANSI code — `di=01;34` means directories get bold blue.
`ls` reads it at startup. If it were empty, `ls --color=always` would emit almost
nothing even though it's trying. (Case-sensitive, American spelling.
`$ls_colours` silently expands to nothing — no error, just emptiness. Normally set
by `dircolors` from `~/.dircolors`.)

**Then we run `ls ... | cat -v`.** This proves `ls` is *emitting* escape codes, by
rendering the non-printing characters visibly — `^[[01;34m` and so on. Whether
they're the *right* codes is a separate question, answered by reading them against
`LS_COLORS`.

**Finally `printf '\e[01;31mRED\e[0m\n'`** verifies that the terminal itself is
rendering colours correctly when handed those characters directly, with `ls`
removed from the picture entirely.

All three checks passed, so no issue was present — the fault was in how I was
observing the output, not in the pipeline.

**The pattern:** bisect the chain and test each link independently. Check the
producer's input, then the producer's output, then substitute a known-good
producer to test the consumer alone. That last move is how you find out which half
of a pipeline is lying.

### Two things visible in the output

**Symbolic links.** The `l` in the first column of `lib64 -> usr/lib64` means
**symlink** — a file whose content is a path to another file. Roughly a Windows
shortcut, except the kernel follows it transparently so most programs never know.
The first character of the ten-character mode field is the file type: `-` regular,
`d` directory, `l` symlink.

**`proc` and `sys` showing size 0** isn't a bug. They're **virtual filesystems** —
kernel state presented as files. Nothing is on disk. `cat /proc/cpuinfo` reads a
data structure the kernel generates on demand.

---

## Exercise 2 — `marco` / `polo`

### Why functions, sourced — not a script

When you *execute* a script, the shell starts a **child process**: a second shell
that inherits a copy of the environment and runs the file. Anything it changes —
variables, working directory — dies with it. So a `cd` inside an executed script
moves the child, the child exits, and you're still where you were.

`source` (or `.`) doesn't spawn anything. It reads the file and runs the commands
*in the current shell*, as if typed.

The rule: **a child process cannot change its parent's environment.** Not a bash
quirk — it's how process creation works on Unix. `fork` copies, and copies
diverge. Same reason a script can't change your `PATH` for you.

Names: **subshell**, **sourcing**, **environment inheritance**. `man bash`, entry
for `source` under Shell Builtin Commands.

### Scripts vs functions

| | Script | Function |
|---|---|---|
| Process | own child process | current shell |
| Can change your cwd/vars | no | yes |
| Discovery | must be on `PATH`, executable | must have been defined (sourced) |
| Language | any — shebang picks the interpreter | bash only |
| Arguments | `$1`, `$@` | same syntax, function's own args |

Rule of thumb: if it must affect your current shell, it's a function. Otherwise a
script — scripts are testable, callable from other programs, and can't corrupt
your session.

### Shell variables

A **shell variable** is a name-to-string binding living in one shell process's
memory. Three properties:

- **Everything is text.** `n=5` stores the character `5`. Arithmetic needs
  explicit syntax: `$((n+1))`.
- **Scope is the process.** Close the terminal and it's gone. A second terminal
  never had it.
- **Shell variables are not environment variables.** An ordinary variable isn't
  passed to child processes. `export` marks it for inheritance, and children then
  receive a *copy*. That's the mechanism behind `PATH` and `LS_COLORS` —
  `LS_COLORS` is exported, which is why `ls`, a separate process, can read it.

`export` is not needed here. `polo` is a function, so it runs in the current shell
and already has access to the variable — there is no process boundary to cross.

And `export` wouldn't rescue a script version either: the child would receive a
copy, `cd` successfully inside itself, and exit. Exporting solves visibility, not
the parent-directory problem.

### Version 1 — file-based (`marco.sh`)

```bash
# shellcheck shell=bash
marco () {
        pwd > /tmp/workdir.txt
}
polo () {
        workdir=$(cat /tmp/workdir.txt)
        cd "$workdir" || return
}
```

### Version 2 — variable-based (`marcovar.sh`)

```bash
# shellcheck shell=bash
marco () {
        workdir=$PWD
}
polo () {
        cd "$workdir" || return
}
```

`$PWD` is a shell variable bash keeps updated with the current directory, so no
command substitution and no subprocess. `$OLDPWD` holds the previous one, and
`cd -` jumps to it — marco/polo for a single hop, built in.

### The tradeoff

| | File | Variable |
|---|---|---|
| Survives shell exit | yes | no |
| Visible to other terminals | yes | no |
| `marco` in window A, `polo` in window B | works | does nothing |
| Concurrent windows | silently clobber each other | independent |
| Leaves state behind | `/tmp/workdir.txt` | nothing |

Neither is wrong. The variable version scopes the state to one shell, which is
what "come back to where I was" usually means, and it's the lecture's answer.

Also: transient runtime data belongs in `/tmp`, not in the repo — a generated file
under version control shows up in `git status` and eventually gets committed. The
general rule is **generated files don't go in version control**, later covering
`__pycache__`, `.venv`, build output and anything with credentials in it.
`.gitignore` is the mechanism; the git lecture covers it.

### Errors I made, in order

I learnt that the shebang wasn't necessary because we weren't writing a script to
be interpreted by another program — we were instead defining a function to be
executed directly by the shell. (It was also written backwards: `!#` instead of
`#!`. The name is **shebang**, from hash-bang; the kernel reads the first two bytes
of an executed file and runs the interpreter named after it. In a sourced file it
is never read at all, so it's just a misleading comment.)

`workdir <` is wrong because bash reads in order and therefore reads `workdir` as
a command to be run, which doesn't exist. `<` redirects input *to a process*; it
can't assign to a variable. The construct I wanted is **command substitution**,
`$(...)`.

`cd workdir` fails for a similar reason: `workdir` is read as text, not as a
variable, so the `$` is needed for the shell to interpret the line correctly. The
quotes are a separate matter — they prevent the expanded result being re-split on
whitespace.

`workdir = $(...)` is wrong because of the spaces: glued `=` assigns a value to
the variable named before the `=`, while separated `=` means the name before it is
read as a command.

`$(workdir)` is the same error as `workdir <` — putting a variable name where bash
expects a command. Parameter expansion is `$name`; command substitution is
`$(cmd)`. Different sigils, different operations.

Three of these — `cd workdir`, `workdir = $()`, `$(workdir)` — share one cause:
**bash decides what a word means from its shape.** `$` makes it an expansion,
`name=` glues into an assignment, quotes make it one word.

### shellcheck

**SC2148** — shellcheck needs to know the dialect (`sh` and `bash` differ, and so
do the checks). It normally reads the shebang. For a sourced file with no shebang,
the intended fix is a **directive comment** as the first line:

```bash
# shellcheck shell=bash
```

**SC2164** — `cd` without a failure branch. Real bug: if `cd` fails, the function
carries on and `polo` silently leaves you where you were while appearing to have
worked. Same class of error as the grep script creating a file on a typo.

But shellcheck's suggested fix, `cd "$workdir" || exit`, is **wrong here**. `exit`
terminates the shell it runs in, and this function is sourced into the interactive
shell — so a failed `cd` would close the terminal. `return` exits the function
only.

`return` for functions, `exit` for scripts; a sourced file has no script to exit
from.

Generalises: linters flag real problems and propose fixes blind to context.
shellcheck doesn't know the file gets sourced. Read the reasoning, not the
suggestion — the same will apply to `ruff` and `mypy`.

