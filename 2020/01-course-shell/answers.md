# Lecture 1 — Course Overview + The Shell (2020)

## Exercise 1 — Check the shell

```bash
echo $SHELL
/bin/bash
```

`$SHELL` is an environment variable holding the **login shell** for my user
account, set in `/etc/passwd`. It is not necessarily the shell currently
interpreting my commands: starting a new shell from inside this one does not
update `$SHELL`. Launching `zsh` from bash leaves `$SHELL` reading `/bin/bash`.

## Exercise 2 — Create /tmp/missing

```bash
mkdir /tmp/missing
```

## Exercise 3 — Look up touch

From the manual: *Update the access and modification times of each FILE to the
current time.*

So the typical purpose of `touch` is to update timestamps, not to create files.
When no file with that path exists, as a fallback `touch` creates an empty one.
The `--no-create` flag suppresses that fallback, leaving only the timestamp job.

A **timestamp** is a recorded moment in time attached to a file. It is
**metadata** — data about the file rather than data in it. Every file carries
three:

- **atime** — access: last time the contents were read
- **mtime** — modification: last time the contents changed
- **ctime** — change: last time the metadata changed (permissions, owner, name)

`touch` sets atime and mtime (`-a` and `-m` select them). ctime cannot be set
directly; it updates as a consequence of other changes, including a `touch`.

Stored as seconds since 1 January 1970 UTC — **Unix time** or **epoch time**.
`ls` formats it for display, but raw epoch integers appear constantly in logs
and datasets.

Why the real job matters: build tools like `make` decide what to rebuild by
comparing mtimes. `touch` on a source file forces a rebuild without editing it.

## Exercise 4 — Create the semester file

```bash
cd /tmp/missing
touch semester
```

First attempt, run from inside `/tmp/missing`:

```bash
touch missing/semester
touch: cannot touch 'missing/semester': No such file or directory
```

`missing/semester` is a **relative path** — resolved starting from the current
working directory (what `pwd` prints). The shell prefixed it, giving
`/tmp/missing/missing/semester`.

An **absolute path** starts with `/` and resolves from the filesystem root
regardless of location. `touch /tmp/missing/semester` would have worked from
anywhere.

The failing component is the second `missing`. `/tmp/missing` exists and
`semester` would have been created — but the intermediate directory does not
exist, and `touch` creates files, never directories. Hence the error names a
missing file or directory rather than a permissions problem.

## Exercise 5 — Write the script

### Attempt 1: what went wrong

[the two commands you ran, the resulting file]
- Where did line 1 go?
- Why was line 2 alone in the file? (two independent reasons)

### Comment stripping

- What does an unquoted `#` do to the rest of the line?
- What did the `hello` test prove about `>`?

### History expansion

- `echo "#!/bin/sh"` — what error, what caused it
- Which quote style stops it, which doesn't
- Interactive-only: why does this matter?

### Redirection

- `>` vs `>>`
- What stdout is, and what `>` actually changes

### Working version

[the two commands, the final file]

## Exercise 6 — Why ./semester fails

- The error
- `ls -l` output
- Mode string broken down: type character, three triples
- Which character is missing
- `-rw-r--r--` = 644, and how the digits are derived

## Exercise 7 — Why sh semester works

- Who opens the file in each case
- Which permission each case requires
- The general rule about scripts and interpreters
```
```

One thing to notice: the shell transcripts in exercises 1 and 4 mix commands with their output, tagged `bash`. That's conventional and readable, but a syntax highlighter will try to parse `/bin/bash` as a command. If it looks wrong on GitHub, drop the language tag on transcript blocks and keep it on pure-command blocks.

Write 5–7 and post the draft.
