# Pausing a Pipeline - Manual Approval

One of the features a lot of CI tools have is the ability to wait for manual approval to move to the next step in a workflow.  This section will go over the functionality that GitHub _does_ have to meet this need, and some of the downsides of it.

[Deployment reviews](https://docs.github.com/en/actions/managing-workflow-runs/reviewing-deployments) are currently the only way to introduce a manual pause into your pipeline.  As it states in the name, this is less about an arbitrary pause and more about reviewing the pipeline results before a deployment.  As such, the functionality is tied to other GitHub features such as [environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment).

Put as simply as possible, instead of setting up a manual approval `step` in your workflow, you will create `Environments` in your repository that require `reviewers` to approve workflows for that environment.  So, let's say you have a workflow with jobs `A`, `B` and `C`, and you want to pause your workflow _before_ `C` runs.  In that case, you'd make an environment for `C` that requires reviewer approval.  When any workflow run gets to job `C`, an email will be sent out to all of the reviewers, and the workflow will pause until the reviewers approve.

This is especially messy because at the time of this writing, GitHub does not provide Environments to non-public repositories in the free plan.
