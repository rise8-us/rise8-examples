# Workflow Dispatch - Manual Triggering of Workflows

This is the simplest example here, and is really only included because the naming is a bit weird.  A `workflow_dispatch` trigger is a manual trigger--the easiest way to manually kick off a workflow from the GitHub interface.

After adding the `workflow_dispatch` trigger to your workflow, trigger your workflow by navigating to:

- Your GitHub Repository main page
- Click the "Actions" tab
- On the left bar, select the name of your workflow
- On the right side, there is a button `Run workflow` that allows you to trigger your workflow.

## Additional Inputs
If you want to get even more enlightened, check out other options that go along with  `workflow_dispatch`, such as adding `inputs` in the [GitHub documentation](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#workflow_dispatch).

A great thing to note is that there is a default dropdown that appears, allowing you to select the branch to run from.  GitHub Actions only knows about workflows that exist in the `default branch`.  So if you're developing a new workflow on a feature branch and you want to manually trigger it, you'll find that the workflow doesn't show up on the Actions page!

There are a couple ways around this:

- Change the `default branch` to the feature branch you are working on
- Start by creating a very simple workflow, similar to the example below, and getting that merged into your `default branch`, before actually developing the workflow

We generally prefer the second option.  Once the simple "Hello World" workflow is on the `default branch`, you can continue developing on your feature branch use the `workflow_dispatch` to trigger your updated code on the feature branch whenever you want using the dropdown!

## Example

Check [this](https://github.com/rise8-us/rise8-examples/blob/main/.github/workflows/workflow_dispatch.yaml) workflow out for an example of creating a `workflow_dispatch`.