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

```bash
echo #!/bin/sh > semester
echo curl --head --silent https://missing.csail.mit.edu > semester
cat semester
curl --head --silent https://missing.csail.mit.edu
```

Line 1 has been deleted entirely from the file. Why is that? Two independent
reasons, both of which had to be fixed:

1. We did not use proper quotation. The `#` marks comments, so everything that
   follows it was read by the shell as a comment instead of a command.
2. We used the `>` operator, which deletes everything previously in the file
   before writing the new content. Even if line 1 had been written correctly,
   line 2 would have wiped it.

Reason 2 is hypothetical here — see the next section for why.

### Comment stripping

As just stated, an unquoted `#` marks the entire rest of the line as a comment.
To be sure the expression is read as text to be written to `semester`, we need
to wrap it in single quotation marks (`'`).

**Comment stripping** happens while the shell parses the line, before anything
is executed. Everything from an unquoted `#` to the end of the line is discarded
— including any operators sitting after it. We can test whether the `>` in a
commented-out line still fires:

```bash
echo hello > semester
echo #!/bin/sh > semester
cat semester
hello
```

`hello` survived. So the `>` in the second line never ran at all: it was
stripped along with the comment, and `semester` was never touched. If it had
run, `hello` would have been gone.

That is why reason 2 above is hypothetical. Line 1 wrote nothing *and* would
have been overwritten — two separate problems that happened to coincide.

The truncating behaviour of `>` is real, though, and shows up as soon as the
quoting is fixed:

```bash
echo hello > semester
echo '#!/bin/sh' > semester
cat semester
#!/bin/sh
```

Here `hello` is gone. To append instead of truncating, use `>>`:

```bash
echo hello > semester
echo '#!/bin/sh' >> semester
cat semester
hello
#!/bin/sh
```

### History expansion

It is important to note the difference between single (`'`) and double (`"`)
quotation marks.

We successfully wrote the first line to `semester` by wrapping it in single
quotes. What happens with double quotes instead?

```bash
echo "#!/bin/sh"
-bash: !/bin/sh: event not found
```

The reason is that some characters, like `!`, keep a special meaning even inside
double quotes. The only way to ensure the line is read as plain text is single
quotation marks.

The mechanism is called **history expansion**: in interactive bash, `!` followed
by text means "find a previous command starting with that text and substitute it
in here". `!!` repeats the last command and `!$` gives its last argument.
`!/bin/sh` matched nothing, so bash refused the whole line — that is what
`event not found` means.

Like comment stripping, this happens early, before the redirection is
considered. So a `>` on the same line would not have saved the command either.

History expansion is **interactive-only**. The same line inside a script runs
fine. This is a real trap: a command that works in a `.sh` file can break when
pasted into the terminal.

N.B: In Bash single and double quotation marks are NOT interchangeable. Single
quotes suppress everything. Double quotes suppress most things — variable
expansion still happens (`"$HOME"` becomes the path) and history expansion still
happens.

### Redirection

The operators `>` and `>>` work by redirecting the output of a command.

In this example we used `echo`, which prints its output to **stdout**. A running
program has three default channels, called **streams**: *stdin* for input
(normally the keyboard), *stdout* for output (normally the screen), and *stderr*
for error messages (also the screen, but a separate channel so errors can be
handled independently).

What the two operators do is not redefine where `echo` prints to, but redefine
what stdout *is* — pointing it at a file instead of the terminal. `echo` behaves
identically either way; it writes to stdout as always, and the shell has already
changed what stdout is connected to before `echo` starts. This is why
redirection works with every command without any command needing to know about
it.

- `>` truncates: empties the file, then writes.
- `>>` appends: writes at the end, keeping what is there.
- `<` redirects stdin, feeding a file to a command as if it had been typed.

A note on vocabulary: **expansion** is the general name for the shell rewriting
your line before executing it. Variable expansion (`$HOME`), history expansion
(`!`), command substitution (`$(date)` becomes that command's output), and glob
expansion (`*.txt` becomes a list of filenames) are all kinds of it. The
unifying idea behind most confusing shell behaviour is that **the command that
runs is rarely the text you typed**.

### Working version

```bash
echo '#!/bin/sh' > semester
echo 'curl --head --silent https://missing.csail.mit.edu' >> semester
cat semester
#!/bin/sh
curl --head --silent https://missing.csail.mit.edu
```

Single quotes are not strictly required on line 2 — it contains no `#` and no
`!`. Quoting by default is the better habit: it means not having to decide,
line by line, whether anything in the string is special.

## Exercise 6 — Why ./semester fails

If we simply try to execute the code of exercise 5 by calling `./semester`, from
`/tmp/missing`, we get:

```bash
./semester
-bash: ./semester: Permission denied
```

We can check the current permissions for `semester` by running `ls -l` from the
same directory:

```bash
ls -l
-rw-r--r-- 1 lucaf lucaf 61 Aug 19 17:01 semester
```

This reveals that no user of the machine, not even the owner, has execute
permission (marked by `x`) for the file.

This string of characters is called the **mode**, and it is structured as
follows:

- The first character denotes the file type: `-` for a regular file, `d` for a
  directory.
- The next three characters are the permissions (`rwx`) for the owner of the
  file. A dash means that permission is absent.
- The next three are the permissions for the owning group (`lucaf`, here).
- The final three are for every other user.

These permissions can also be written numerically. `-rw-r--r--` = 644: each
triple becomes a single digit, the sum of the permissions present, under the
rule `r` = 4, `w` = 2, `x` = 1. So `rw-` = 6 and `r--` = 4.

This is the same `644` that appeared in git's output when the file was first
committed — `create mode 100644`.

## Exercise 7 — Why sh semester works

Unlike exercise 6, in this case we run:

```bash
sh semester
```

This successfully executes the code in `semester`, unlike what happened in
exercise 6. Why?

The reason is that `sh` is a program that:

1. we have permission to execute (`/bin/sh` is `rwxr-xr-x`), and
2. only needs to be able to *read* the contents of `semester`, which it can.

So when running a script directly, we need permission to execute it. When
running it through an **interpreter** — a program that reads source code and
carries out its instructions, rather than the file being run by the kernel
itself — we only need permission to read the file as data.

This is why non-executable source files can still be run by interpreters:
`python script.py` works on a `.py` file with no `x` bit, for the same reason.

The general rule: the `x` bit on a script is permission for the file to be
*launched directly*, not permission for its contents to run. The contents are
always ultimately executed by an interpreter that has its own `x` bit.

## Exercise 8 — chmod

```bash
ls -l semester
-rw-r--r-- 1 lucaf lucaf 61 Aug 19 21:18 semester

chmod u+x semester

ls -l semester
-rwxr--r-- 1 lucaf lucaf 61 Aug 19 21:18 semester
```

`chmod` takes two notations. The **symbolic** form used here names who and what:
`u` (user/owner), `g` (group), `o` (others), `a` (all), combined with `+` to add
a permission, `-` to remove one, `=` to set exactly. The **numeric** form
restates the whole mode at once: `chmod 755 semester` would have worked too.

Symbolic is the safer default. `u+x` says only what is changing and leaves
everything else alone; `755` restates all nine bits, so a mistake silently
rewrites permissions that were fine.

## Exercise 9 — How the shell knows to use sh

I initially thought that the shell read the shebang. In reality it is the
**kernel**.

The kernel is the core of the operating system: the program that talks to the
hardware and controls what every other program is allowed to do. It is always
running, and nothing else touches disk, memory or CPU directly. The shell is an
ordinary program with no special powers — it cannot run anything itself, it can
only ask the kernel to.

The **shebang** is the `#!` on the first line, followed by the path to an
interpreter. `#!` is a **magic number**: a fixed byte sequence at the start of a
file that identifies its type. The kernel checks for several; `#!` means
"interpreted script".

What happens on `./semester`:

1. Bash asks the kernel to execute `/tmp/missing/semester`.
2. The kernel checks whether `lucaf` may execute that file. This needs `x`,
   which is what exercise 8 added.
3. The kernel opens the file, sees `#!` in the first two bytes, and reads the
   path that follows.
4. The kernel checks whether `lucaf` may execute `/bin/sh`.
5. The kernel launches `/bin/sh` with `semester` as its argument.

At the end of the day, in both cases we are running `sh` with `semester` as its
argument. The only difference is that in the first case the shebang tells the
kernel which program to use, while in the second case we name `sh` ourselves.

What changes is the permissions required. `./semester` needs `x` on `semester`
*and* `x` on `/bin/sh`. `sh semester` needs only `x` on `/bin/sh`, plus `r` on
`semester`, which is opened as data. The direct form is the indirect form plus
one extra check — which is precisely why mode 644 was enough in exercise 7 and
not enough in exercise 6.

On the second check: permissions belong to files, not to running programs. The
question is always whether *the user* may do the thing. Every process runs as
some user and inherits that identity — the **effective user ID**, which `whoami`
prints. `/bin/sh` is owned by root with mode `rwxr-xr-x`, so `lucaf` is neither
owner nor in the owning group and falls through to the last triple. The `x` in
that final `r-x` is the permission being used.

Note that `/bin/sh` is a symlink — a file that points at another file. On Ubuntu
it points to `dash`, a smaller and faster shell than bash. `ls -l /bin/sh` shows
the target.

A file with no shebang cannot be identified by the kernel and execution fails.
Some shells then retry it themselves as a fallback, which masks the problem.
