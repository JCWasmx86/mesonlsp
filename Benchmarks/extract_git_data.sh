#!/usr/bin/env bash
echo "DIFFS= ["

tags=$(git tag | grep -v v1.2.1 | grep -v v2.3.3 | grep -v v2.3.4 | grep -v v2.3.5 | grep -v v2.3.6 | grep -v 2.3.7 | grep -v 2.3.8 | grep -v 2.3.9 | grep -v 2.3.10 | grep -v 2.3.11 | grep -v 2.3.12)
previous_tag=""
for tag in $tags; do
	if [[ $tag == "v1.0" ]]; then
		diff_output=$(git diff --shortstat "$tag")
	else
		diff_output=$(git diff --shortstat "$previous_tag" "$tag")
	fi
	files_changed=$(echo "$diff_output" | awk '{print $1}')
	insertions=$(echo "$diff_output" | awk '{print $4}')
	deletions=$(echo "$diff_output" | awk '{print $6}')
	if [[ $tag == "v1.0" ]]; then
		commit_count=$(git rev-list --count "$tag")
	else
		commit_count=$(git rev-list --count "$previous_tag".."$tag")
	fi
	echo "[$files_changed, $insertions, $deletions, $commit_count],"
	previous_tag=$tag
done

echo "]"
