#!/bin/bash
set -eo pipefail

ID=$1

function loop_through_jobs () {

  JOBID=$(gh run list -R https://github.com/rise8-us/rise8-examples --json name,databaseId | jq -r --arg uid $ID '.[] | select(.name == $uid) | .databaseId')
  if [[ ! -z $JOBID ]]; then
    gh run watch -R https://github.com/rise8-us/rise8-examples $JOBID --exit-status

    if [[ $? -eq 0 ]]; then
      echo "Workflow completed successfully, exiting!"
      exit 0
    else
      echo "Workflow failed, check logs at: $(gh run view $JOBID -R https://github.com/rise8-us/rise8-examples --json url -q '.url')"
      exit 1
    fi
  fi
}

function find_status () {
  for i in {1..5}; do
    loop_through_jobs
    sleep 10s
  done
  echo "ERROR: Could not find workflow run with UUID $ID!"
  exit 2
}

echo $REPO_DISPATCH_PAT | gh auth login --with-token
find_status