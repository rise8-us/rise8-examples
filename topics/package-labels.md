# Publishing Images to GitHub Package - Advanced Labels

When using GitHub Actions to publish container images to GitHub Packages, the general use-case defined below just "works":

- Have one or more `Dockerfile`s in your repository
- Use the marketplace `build-and-push` action to build and push your image to your repositories Github Packages registry

However, trying to use this flow while also modifying the images label metadata can cause unexpected behavior.

While the default behavior is that the image you build via GitHub Actions will be published to that repositories package registry, if you specify the image label `org.opencontainers.image.source` as a _different_ repository, the image will automatically be published to that repositories registry instead.  This can also lead to build issues because now you will need a Personal Access Token instead of the auto-generated `GITHUB_TOKEN` to publish this image.

Details about labelling of container images can be found [here](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#labelling-container-images).