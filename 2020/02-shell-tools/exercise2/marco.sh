# shellcheck shell=bash

marco () {
	pwd > /tmp/workdir.txt
}

polo () {
	workdir=$(cat /tmp/workdir.txt)
	cd "$workdir" || return
}
