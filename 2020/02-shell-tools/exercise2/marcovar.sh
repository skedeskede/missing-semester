# shellcheck shell=bash

marco () {
	workdir=$PWD
}

polo () {
	cd "$workdir" || return
}
