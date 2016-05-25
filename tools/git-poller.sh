#!/bin/bash

remote="origin"
branch="master"
delay=60

cd /home/bigrandall/auto-deploy

# Start-up: Ensure prev-head exists, then read it in.
if [ ! -f .gitpoller-prev-head ]; then
	git rev-parse $branch > .gitpoller-prev-head
fi
prev_head="$(cat .gitpoller-prev-head)"

while true ; do
	echo "Checking for updates to $remote/$branch"
	git fetch > .gitpoller-fetch-log 2>&1
	if [ $? -ne 0 ]; then
		echo "Fetch from git exited with $?. Log is as follows:"
		cat .gitpoller-fetch-log
		echo "Aborting."
		exit 1
	fi

	remote_head="$(git rev-parse $remote/$branch)"
	if [ $? -ne 0 ]; then
		echo "Getting rev for $remote/branch exited with $?"
		echo "Read in: $remote_head"
		echo "Aborting."
		exit 1
	fi

	if [ "$remote_head" == "$prev_head" ]; then
		sleep $delay
		continue
	fi

	echo "Looks like things changed."
	echo "  Old head: $prev_head"
	echo "  New head: $remote_head"

	git merge --ff-only $remote/$branch
	if [ $? -ne 0 ]; then
		echo "Unable to resolve differences via fast-forward."
		echo "Aborting."
	fi

	rsync -av /home/bigrandall/auto-deploy/site/ /home/bigrandall/bigrandall.com/

	echo "$remote_head" > .gitpoller-prev-head
	prev_head="$remote_head"
	sleep $delay
done

