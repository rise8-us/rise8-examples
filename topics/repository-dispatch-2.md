# Repository Dispatch - Polling for Run

One of the biggest features lacking in the GitHub Actions space today is centered around `repository_dispatch` events.  When a `repository_dispatch` is triggered via an API call, the response does not contain any return information, meaning that you as a developer have no way to know information including the success/failure/completion-time of the called workflow.  You could consider just getting all of the recent runs triggered, but you're very much in a race condition world!

Thanks to a newer feature GitHub Actions recently released, there is a viable workaround to this, although it's not pretty.  What unlocks this possibility is somewhat obscure, and that's [Dynamic names for workflow runs](https://github.blog/changelog/2022-09-26-github-actions-dynamic-names-for-workflow-runs/).  Here's how Dynamic names help us solve our problem:

- Caller workflow generates some unique name, such as a UUID
- Caller workflow passes the UUID to the called workflow via it's `client_payload` data when triggering the `repository_dispatch`
- Called workflow uses the syntax run-name: `${{ github.event.client_payload.id }}`, which dynamically names the workflow the UUID value.
- Caller, after triggering the `repository_dispatch`, now can poll the workflow runs to find one who's name is the UUID!
- Caller, once the workflow with the UUID is found, can either poll or use the GitHub CLI `gh run watch` to watch that run for it's completion results.

## Example

Working code for this section:

- [Triggering a repository_dispatch and polling](../.github/workflows/repository_dispatch_caller.yaml)
- [Listening for a repository_dispatch using a dynamic name](../.github/workflows/repository_dispatch_called.yaml)
- [Polling script](../.github/scripts/workflow-status.sh)

In the case of the example above, you can see a workflow get generated with a random ID:
![example](../images/poll_example.png)