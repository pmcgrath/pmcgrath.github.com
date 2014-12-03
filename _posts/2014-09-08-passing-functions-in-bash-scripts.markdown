---
layout: post
title: Passing functions in a bash script
categories: bash
---


## Reminder so I can remember this

```bash
#!/usr/bin/env bash
set -e	# Stop on first error, see http://www.tldp.org/LDP/abs/html/options.html
#set -v	# Show command, see http://www.tldp.org/LDP/abs/html/options.html

ensure_sudo()
{
	if [ $(whoami) == 'root' ]; then
		echo You must run this script as root !
		exit 1
	fi
}

ensure_required_parameters_passed()
{
	local -r expected_parameter_count=${1}
	local -r usage=${2}
	local -r actual_parameter_count=$#
	local -r command_parameter_count=$((actual_parameter_count-4)) # 4 is for expected parameter count, usage, command functions and command name

	if [ $command_parameter_count -ne $expected_parameter_count ]
	then
		echo Expected $expected_parameter_count parameters but got $command_parameter_count !
		echo -e $usage
		exit 1
	fi
}

build()
{
	local -r p1=${1}
	local -r p2=${2}
	echo "Building for [$p1] and [$p2]"
}

run()
{
	local -r p1=${1}
	echo "Running for [$p1]"
}

execute()
{
	ensure_sudo
	ensure_required_parameters_passed "$@"

	echo About to invoke command
	command_function=${3}
	shift 4
	$command_function "$@"

	echo Completed command
}

main()
{
	case "$1" in
		"build")
			execute 2 "Usage\n$0 build p1 p2\nwhere\np1 is ...\np2 is ...\n" build "$@"
			;;
		"run")
			execute 1 "Usage\n$0 run p1\nwhere\np1 is ...\n" run "$@"
			;;
		*)
			echo "Unknown command [$1] !"
	esac

	exit 0
}

main "$@"
```


## Sample outputs after saving the above as a.sh and setting execute permission

```bash
./a.sh build p1 p2
> About to invoke command
> Building for [p1] and [p2]
> Completed command

./a.sh run p1
> About to invoke command
> Running for [p1]
> Completed command

./a.sh exec p1
> Unknown command [exec] !

./a.sh build p1
> Expected 2 parameters but got 1 !
> Usage
> ./a.sh build p1 p2
> where
> p1 is ...
> p2 is ...
```

