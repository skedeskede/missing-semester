# Lecture 1 — Course Overview + The Shell (2020)

## Exercise 1 — Check the shell

```
echo $SHELL
/bin/bash
```

## Exercise 2 — Create /tmp/missing

```
mkdir /tmp/missing
```


## Exercise 3 — Look up touch

From the manual, the description of touch is: Update the access and modification times of each FILE to the current time.

This means that the typical purpose of touch is to update timestamps, not create new files. However, when a file with that path does not yet exist, as a fallback touch will create a new file.

## Exercise 4 — Create the semester file

Following Exercise 3 we run

```
cd /tmp/missing
touch semester
```

N.B: Initially we were sitting in /tmp/missing and we tried to run:
```
touch missing/semester
```
This gave an error. The reason for that is that the shell interpreted the path as /tmp/missing/missing/semester
The issue here is that touch only creates files, not directories, so it was unable to create the second missing directory when it does not exist yet.
