#!/usr/bin/env bash

commit_msg=$(cat "$1")
echo "$commit_msg" | commitlint