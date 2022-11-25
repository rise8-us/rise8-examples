# Advanced GitHub Actions - Tips & Tricks

GitHub Actions is a CI/CD tool that is in active development by GitHub.  Because of this, while it is very easy to get started, it can sometimes be challenging to sift through outdated StackOverflow articles to do a specific thing, if you even know it exists!  While the GitHub Actions documentation is fantastic, you have to know what's there and what's been added since you've looked last.

This post attempts to resolve the issue by existing as a living document that gathers advanced features and explanations all in one place.  Our team follows the GitHub Actions RSS feed to always be looped into the new features coming out.  By knowing what's possible and how to achieve it, your CI/CD workflows will reach their greatest potential :muscle:.

# Table of Contents
- [Workflow Dispatch - Manual Triggering of Workflows](#workflow-dispatch---manual-triggering-of-workflows)
    - [Example](#example)
- [Repository Dispatch - Triggering Another Workflow](#repository-dispatch---triggering-another-workflow)
    - [Example](#example-1)
- [Repository Dispatch - Polling for Run](#repository-dispatch---polling-for-run)
- [Custom Actions vs Reusable Workflows](#custom-actions-vs-reusable-workflows)
- [Pausing a Pipeline - Manual Approval](#pausing-a-pipeline---manual-approval)
- [Matrix](#matrix)

## Workflow Dispatch - Manual Triggering of Workflows

This is the simplest example here, and is really only included because the naming is a bit weird.  A `workflow_dispatch` trigger is a manual trigger--the easiest way to manually kick off a workflow from the GitHub interface.

After adding the `workflow_dispatch` trigger to your workflow, trigger your workflow by navigating to:

- Your GitHub Repository main page
- Click the "Actions" tab
- On the left bar, select the name of your workflow
- On the right side, there is a button `Run workflow` that allows you to trigger your workflow.

### Additional Inputs
If you want to get even more enlightened, check out other options that go along with  `workflow_dispatch`, such as adding `inputs` in the [GitHub documentation](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#workflow_dispatch).

A great thing to note is that there is a default dropdown that appears, allowing you to select the branch to run from.  GitHub Actions only knows about workflows that exist in the `default branch`.  So if you're developing a new workflow on a feature branch and you want to manually trigger it, you'll find that the workflow doesn't show up on the Actions page!

There are a couple ways around this:

- Change the `default branch` to the feature branch you are working on
- Start by creating a very simple workflow, similar to the example below, and getting that merged into your `default branch`, before actually developing the workflow

We generally prefer the second option.  Once the simple "Hello World" workflow is on the `default branch`, you can continue developing on your feature branch use the `workflow_dispatch` to trigger your updated code on the feature branch whenever you want using the dropdown!

### Example

Check [this](./.github/workflows/workflow_dispatch.yaml) workflow out for an example of creating a `workflow_dispatch`.

## Repository Dispatch - Triggering Another Workflow

You've learned a lot of the simple ways to trigger pipelines already:

- `push`
- `pull_request`
- `workflow_dispatch`

But what about linking pipelines--having one pipeline trigger another?  That is the job of a `repository_dispatch`, of which you can learn more about [here](https://docs.github.com/en/rest/repos/repos#create-a-repository-dispatch-event).
There are two parts to a `repository_dispatch` event:

1. Creating a trigger event
1. Listening for a trigger event

### Creating an Event

To create an event, the simplest way is to just execute an HTTP POST command via `curl`.  Here is the example that GitHub gives:

```bash
curl \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer <YOUR-TOKEN>" \
  https://api.github.com/repos/OWNER/REPO/dispatches \
  -d '{"event_type":"on-demand-test","client_payload":{"unit":false,"integration":true}}'
```

See the linked GitHub documentation above for requirements on generating the token to replace `<YOUR-TOKEN>`.  Remember that the creator of this token must have privileges on the GitHub repository for which you'd like to trigger.

Note also the data (denoted by `-d` line) here.  There are two pieces of the `json` data:

1. `event_type` - this is the webhook (trigger) name.  Since you can have as many different `repository_dispatch` events as you want, differentiates them.  As you'll see in [listening for an event](#listening-for-an-event), a workflow can listen for as many `repository_dispatch` events as you wish.
2. `client_payload` - this is any data to send to the workflow you wish to trigger.  Often times, you'll want additional data to be sent such as results from the triggering pipeline.

### Listening for an Event

Listening for a `repository_dispatch` event is as simple as adding it to the `on:` block of a workflow.  You can listen for as many different dispatch events as you want, and handle them differently in your code.  See the working example below for inspiration!

### Example

Working code for this section:

- [Triggering a repository_dispatch](./.github/workflows/repository_dispatch_trigger.yaml)
- [Listening for a repository_dispatch](./.github/workflows/repository_dispatch_listener.yaml)

## Repository Dispatch - Polling for Run

One of the biggest features lacking in the GitHub Actions space today is centered around `repository_dispatch` events.  When a `repository_dispatch` is triggered via an API call, the response does not contain any return information, meaning that you as a developer have no way to know information including the success/failure/completion-time of the called workflow.  You could consider just getting all of the recent runs triggered, but you're very much in a race condition world!

Thanks to a newer feature GitHub Actions recently released, there is a viable workaround to this, although it's not pretty.  What unlocks this possibility is somewhat obscure, and that's [Dynamic names for workflow runs](https://github.blog/changelog/2022-09-26-github-actions-dynamic-names-for-workflow-runs/).  Here's how Dynamic names help us solve our problem:

- Caller workflow generates some unique name, such as a UUID
- Caller workflow passes the UUID to the called workflow via it's `client_payload` data when triggering the `repository_dispatch`
- Called workflow uses the syntax run-name: `${{ github.event.client_payload.id }}`, which dynamically names the workflow the UUID value.
- Caller, after triggering the `repository_dispatch`, now can poll the workflow runs to find one who's name is the UUID!
- Caller, once the workflow with the UUID is found, can either poll or use the GitHub CLI `gh run watch` to watch that run for it's completion results.

### Example

Working code for this section:

- [Triggering a repository_dispatch and polling](./.github/workflows/repository_dispatch_caller.yaml)
- [Listening for a repository_dispatch using a dynamic name](./.github/workflows/repository_dispatch_called.yaml)
- [Polling script](./.github/scripts/workflow-status.sh)

In the case of the example above, you can see a workflow get generated with a random ID:
![example](./images/poll_example.png)

## Custom Actions vs Reusable Workflows

One of the things we see with people getting started with GitHub Actions is confusion around creating an action vs creating a reusable workflow.  They have two distinct use-cases, but often they can be use together to make a powerful solution.

### Reusable Workflows
You can think of [reusable workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows) as templates of workflows.  A critical thing to know about them is that they are **not** triggered directly, but rather are referenced in another workflow.  When a workflow uses a reusable flow, GitHub behind-the-scenes actually downloads it and runs it.  This leads to the next most important thing to note--the reusable workflow actually executes in the _context of the caller_.  This has **very** important ramifications, as seen in the example below:

- Repository `A` has reusable workflow `X`
    - reusable workflow `X` references a GitHub Secret `${{ secrets.password }}`
- Repository `B` has workflow `Y`

When workflow `Y` is triggered, it calls the reusable flow `X`, which references `${{ secrets.password }}`.  And here we come to it--even though reusable flow `X` lives in repository `A`, because it's executing in the context of repository `B`, **repository `B` must have defined the secret `${{ secrets.password }}`**.  Put another way, the reusable workflow brings no state with it when called.

The fact that reusable workflows bring no state can be challenging.  For example, you cannot directly include helper script files alongside your reusable workflow.  In addition, it means that the the caller of your reusable workflow must have all of the information necessary to execute it.  This can make some security practices challenging, such as if you'd like your reusable workflow to perform encryption or signing of data, those secret keys must be distributed, or accessible to, to all repositories that will use the flow.

#### Example

- [Reusable Flow](./.github/workflows/reusable_flow_called.yaml)
- [Workflow that calls Reusable Flow](./.github/workflows/reusable_flow_caller.yaml)

In the case of the example above, you can see the caller workflow calling the reusable flow below.  Take note how you can see the reusable workflow steps and output just as if it were the workflow you triggered yourself:
![example](./images/reusable.png)


### Custom Actions
Custom Actions are probably more common than Reusable Flows, as GitHub Actions promotes them right when you get started using it.  Any of the actions created and available on the [GitHub Marketplace](https://github.com/marketplace?type=actions) are all Custom Actions created by someone else.  At it's core, a Custom Action is just a wrapper around some code.

Since you're reading this though, you're more likely interested in creating your own Custom Actions.  Beyond the basic documentation for [creating a custom action](https://docs.github.com/en/actions/creating-actions), a key difference between them and Reusable Workflows is that when using an action, you automatically have access to _all of the files in the custom action_.  This means that if you want the Custom Action to be comprised of multiple Javascript files, or even stateful JSON data, it will all available when called.

Custom Actions currently can happen in two forms:

- A dedicated repository
- A folder in an existing repository

#### Dedicated Repository Action
These type of actions are what you see in the GitHub marketplace.  They will always have a top level `action.yml` file such as [this one for stale issues](https://github.com/actions/stale).  To use them, you can simply use the following syntax:

```bash
jobs:
  stale:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/stale@v6
        with:
          stale-issue-message: 'Stale issue message'
          ...
```

Where `actions/stale@v6` references the action in the format <REPOSITORY>@<BRANCH/TAG>.  You can create your own custom action the same way, and you do not need to publish it to the marketplace to use it.  However, keep in mind the GitHub Custom Action repository must either be `public`, or the repository you are using it from must have proper access (i.e. it's `internal` and in the same organization).  We will omit an example from this section as it's basic functionality for GitHub Actions.
#### Directory-based Action
If you run into a scenario where you'd prefer to house multiple Custom Actions in the same repository, or maybe modularize your code by having a Custom Action in the same repository as your workflow, you can also store the action anywhere in a repository.  The key here is that the repository that holds the Custom Action **must be checked out prior to use**.  To use a Custom Action in this manner, the syntax is as follows:

```bash
jobs:
  stale:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: Run Custom Action
        uses: ./.github/actions/custom-action
```
Where `./.github/actions/custom-action` is a folder in the repository and is structured according to the documentation for [creating a custom action](https://docs.github.com/en/actions/creating-actions).

##### Example

- [Custom Action](./.github/actions/common/action.yml)
- [Workflow that calls Custom Action](./.github/workflows/custom_action.yaml)
In the case of the example above, you can see the output of the Custom Action, including some JSON Data, here:
![example](./images/custom_action.png)

## Pausing a Pipeline - Manual Approval

One of the features a lot of CI tools have is the ability to wait for manual approval to move to the next step in a workflow.  This section will go over the functionality that GitHub _does_ have to meet this need, and some of the downsides of it.

[Deployment reviews](https://docs.github.com/en/actions/managing-workflow-runs/reviewing-deployments) are currently the only way to introduce a manual pause into your pipeline.  As it states in the name, this is less about an arbitrary pause and more about reviewing the pipeline results before a deployment.  As such, the functionality is tied to other GitHub features such as [environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment).

Put as simply as possible, instead of setting up a manual approval `step` in your workflow, you will create `Environments` in your repository that require `reviewers` to approve workflows for that environment.  So, let's say you have a workflow with jobs `A`, `B` and `C`, and you want to pause your workflow _before_ `C` runs.  In that case, you'd make an environment for `C` that requires reviewer approval.  When any workflow run gets to job `C`, an email will be sent out to all of the reviewers, and the workflow will pause until the reviewers approve.

This is especially messy because at the time of this writing, GitHub does not provide Environments to non-public repositories in the free plan.

## Matrix
# TODD