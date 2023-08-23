# Unified CI: Streamlining GitHub Workflows Across Repositories

![web3-bot](./web3-bot.png)

Welcome to Unified CI, your key to deploying and managing GitHub Actions workflows across an extensive network of repositories. Unified CI takes the helm in orchestrating both the initial deployment and ongoing updates of workflows, providing a seamless solution to streamline your projects' lifecycle.

With Unified CI at your side, Protocol Labs can effortlessly oversee GitHub Actions workflows throughout numerous organizations and hundreds of repositories. This automated system guarantees:

1. **Consistency**: Through the utilization of identical GitHub Actions workflow definitions across participating repositories, Unified CI assures that code maintains the highest standard and undergoes thorough testing.
2. **Maintainability**: Workflow definitions are constantly refreshed under Unified CI's management. Any changes in the definitions are instantly relayed to all participating repositories, guaranteeing up-to-date operations.

## Availability and Future Directions

Unified CI is currently available for both Go and JavaScript (JS), providing a wide array of automated services for each:

- **Go**: Unified CI's Go support includes testing with the current and previous versions of Go, and performing tests on Windows, macOS, and Linux. It ensures comprehensive testing, including on 32-bit infrastructure, and for race conditions. Besides testing, it also handles linting and formatting for Go code, providing a well-rounded CI solution. Moreover, the release process is also automated via GitHub Releases.

- **JavaScript**: For JavaScript, Unified CI ensures testing across various platforms: Windows, Linux, and macOS. It also conducts tests in multiple environments, including Node, Chrome, Firefox, Webkit, WebWorkers, and Electron. Similar to Go, it also automates the release process, ensuring a streamlined workflow.

We understand the growing needs of different programming languages in the development community, and we're excited to share that we have plans to extend Unified CI support to Rust and Python. This will allow us to provide our robust CI solution to an even broader range of developers. Stay tuned for future updates on this expansion!

## Fine-tuning Your Unified CI Experience

Most repositories won't need any customization, and the workflows defined here will just work fine.

### Configuration Variables

Some aspects of Unified CI workflows are configurable through [configuration variables](https://docs.github.com/en/actions/learn-github-actions/variables#creating-configuration-variables-for-a-repository).

You can customise the runner type for `go-test` through `UCI_GO_TEST_RUNNER_UBUNTU`, `UCI_GO_TEST_RUNNER_WINDOWS` and `UCI_GO_TEST_RUNNER_MACOS` configuration variables. This option will be useful for repositories wanting to use more powerful, [PL self-hosted GitHub Actions runners](https://github.com/pl-strflt/tf-aws-gh-runner). Make sure the value of the variable is valid JSON.

`UCI_*_RUNNER_*` variables expect the values to be JSON formatted. For example, if you want the `MacOS` runner used in `Go Test` workflow to be `macos-12` specifically, you'd set `UCI_GO_TEST_RUNNER_MACOS` to `"macos-12"` (notice the `"` around the string); and if you want your `Ubuntu` runner to be a self hosted machine with labels `this`, `is`, `my`, `self-hosted`, `runner`, you'd set `UCI_GO_TEST_RUNNER_UBUNTU` to `["this", "is", "my", "self-hosted", "runner"]`.

### Setup Actions

Some repositories may require some pre-setup steps to be run before tests (or code checks) can be run. Setup steps for `go-test` are defined in `.github/actions/go-test-setup/action.yml`, and setup steps for `go-check` are defined in `.github/actions/go-check-setup/action.yml`, in the following format:

```yml
runs:
  using: "composite"
  steps:
    - name: Step 1
      shell: bash
      run: echo "do some initial setup"
    - name: Step 2
      shell: bash
      run: echo "do some Linux-specific setup"
      if: ${{ matrix.os == 'ubuntu' }}
```

These setup steps are run after the repository has been checked out and after Go has been installed, but before any tests or checks are run.
If you need to access the GitHub Token in a setup action, you can do so through `github.token` variable in the [`github` context](https://docs.github.com/en/actions/learn-github-actions/contexts#github-context). Unfortunately, the actions do not have access to the [`secrets` context](https://docs.github.com/en/actions/learn-github-actions/contexts#secrets-context).

### Configuration Files

#### Global Configuration Files

You can configure Unified CI for your repository by creating a `.github/uci.yml` configuration file.

Here is an example configuration file:
```yml
files: # Configure what Unified CI templates should be used for your repository; defaults to primary language default fileset
  - .github/workflows/go-check.yml
  - .github/workflows/go-test.yml
  - .github/workflows/release.yml
force: true # Configure whether Unified CI should overwrite existing workflows; defaults to false
versions:
  uci: v1 # Configure what version of Unified CI reusables should be used; defaults to latest
  go: 1.21 # Configure what version of Go should be used; defaults to oldstable
```

#### Job Specific Configuration Files

`go-check` contains an optional step that checks that running `go generate` doesn't change any files.
This is useful to make sure that the generated code stays in sync.

This check will be run in repositories that set `gogenerate` to `true` in `.github/workflows/go-check-config.json`:
```json
{
  "gogenerate": true
}
```

Note that depending on the code generators used, it might be necessary to [install those first](#additional-setup-steps).
The generators must also be deterministic, to prevent CI from getting different results each time.

`go-test` offers an option to completely disable running 32-bit tests.
This option is useful when a project or its upstream dependencies are not 32-bit compatible.
Typically, such tests can be disabled using [build constraints](https://pkg.go.dev/cmd/go#hdr-Build_constraints).
However, the constraints must be set per go file, which can be cumbersome for a project with many files.
Using this option, 32-bit tests can be skipped entirely without having to specify build constraints per file.

To completely disable running 32-bit and/or race detection tests set `skip32bit`/`skipRace` to `true` in `.github/workflows/go-test-config.json`:
```json
{
  "skip32bit": true,
  "skipRace": true
}
```

If your project cannot be built on one of the supported operating systems, you can disable it by setting `skipOSes` to a list of operating systems in `.github/workflows/go-test-config.json`:
```json
{
  "skipOSes": ["windows", "macos"]
}
```

If you want to disable verbose logging or test shuffling, you can do so by setting `verbose` or `shuffle` to `false` in `.github/workflows/go-test-config.json`:
```json
{
  "verbose": false,
  "shuffle": false
}
```

### Workflow Modification

You can modify the workflows distributed by Unified CI as you wish. Unified CI will only ever try to update the versions of reusables after the initial distribution. Similarly to how dependabot operates.

In particular, you might want to update the organization part of the reusable's path to your organization in case your organization doesn't allow using reusables from outside organization or you intend to run reusables on self-hosted runners. If you fork the Unified CI repository and give write access to your fork to @web3-bot, your fork is going to be kept up to date automatically. This ensures the validity of all future, automatic Unified CI updates.

## Usage

Unified CI is distributed to all repositories @web3-bot has write access to.

If you want your project to participle, give [@web3-bot](https://github.com/web3-bot) write access to your repository. If the invitation needs acceptance, please create an issue or reach out to us at [#ipdx](https://filecoinproject.slack.com/archives/C03KLC57LKB).

## Structure

Unified CI consists of [templates](./templates/) which are [rendered](./scripts/render-template.sh) using the combination of [default configuration](./.github/workflows/copy-templates.yml) and [repository specific configuration](#global-configuration-files) and distributed to [participating repositories](#usage) on [schedule](./.github/workflows/copy-templates.yml) by [Copy](./.github/workflows/copy-templates.yml) workflow. Distributed changes are proposed as Pull Requests by [Create](./.github/workflows/create-prs.yml) workflow and automatically merged by [Merge](./.github/workflows/merge-prs.yml) workflow when allowed.

All workflow [templates](./templates/) distributed by Unified CI reference [reusables](./.github/workflows/) which live in Unified CI repository. By default, [Copy](./.github/workflows/copy-templates.yml) workflow proposes updates **ONLY** to the versions of [reusables](./.github/workflows/) - the same way [dependabot](https://github.com/dependabot/dependabot) operates. This ensures users are free to modify the workflows after distribution as they wish.

Unified CI repository can be forked to accomodate repositories that don't allow usage of reusables from outside the organization or intend to run reusables on self-hosted runners. The forks to which @web3-bot has write access are kept up to date automatically by [Sync](./.github/workflows/sync-forks.yml) workflow. This ensures the validity of all future, automatic Unified CI updates.

## Templates

<details><summary>release.yml, release-check.yml, tagpush.yml, version.json</summary>

### Versioning

Go versioning uses [Semantic Versioning 2.0.0](https://semver.org/).

On a high level, this means that given a version number MAJOR.MINOR.PATCH, one is supposed to increment the:

* MAJOR version when you make incompatible API changes,
* MINOR version when you add functionality in a backwards compatible manner, and
* PATCH version when you make backwards compatible bug fixes.

For `v0` versions, incompatible API changes only require a MINOR version bump.

The Go tooling uses version numbers to infer which upgrades are safe (in the sense that they don't result in breaking the build). For example `go get -u=patch` updates dependencies to the most recent patch release. Our downstream users also expect that their compilation won't break when they update to a patch release.

Special care has to be taken when cutting a new release after updating dependencies. Even though a dependency update might not change the API of a package and might therefore _look_ as if it was backwards-compatible change, this is not true if the update of that package is more than a patch release update (i.e., it is a minor or a major release): Go's Minimum Version Selection will force all downstream users to use the new version _of the dependency_, which in turn might lead to breakages in downstream code. Updating a dependency (other than patch releases) therefore MUST result in a bump of the minor version number.

It has turned out that manually assigning version numbers is easy to mess up. To make matters worse, GitHub doesn't give us the option to apply our code review process to releases: A new Go release is created everytime a tag starting with `v` is pushed. Once pushed, the release is picked up by the Google module proxy in a very short time frame, which means that in practice, it's not possible to delete an errorneous pushed tag.

Instead of manually tagging versions, we use GitHub Actions workflows to aid us picking the right version number.

#### Using the Versioning Workflows

Every Go repository contains a `version.json` file in the root directory:
```json
{
  "version": "v0.4.2"
}
```

This version file defines the currently released version.

When cutting a new release, open a Pull Request that bumps the version number and have it review by your team mates.
The [release check workflow](.github/workflows/release-check.yml) will create a draft GitHub Release (_if the workflow was not initiated by a PR from a fork_) and post a link to it along with other useful information (the output of `gorelease`, `gocompat` and a diff of the `go.mod` files(s)).

As soon as the PR is merged into the default branch, the [releaser workflow](.github/workflows/releaser.yml) is run. This workflow either publishes the draft GitHub Release created by the release check workflow or creates a published GitHub Release if it doesn't exist yet. This, in turn, will create a new Git tag and push it to the repository.

##### Modifying GitHub Release

All modification you make to the draft GitHub Release created by the release check workflow will be preserved. You can change its' name and body to describe the release in more detail.

##### Using a Release Branch

Sometimes it's necessary to cut releases on a release branch. If you open a Pull Request targeting a branch other than the default branch, a new release will only be created if the PR has the `release` label.

##### Dealing with Manual Pushes

Unfortunately, GitHub doesn't allow us to disable / restrict pushing of Git tags (see this long-standing [Feature Request](https://github.community/t/feature-request-protected-tags/1742), and consider upvoting it ;)). We can however run a [workflow](.github/workflows/tagpush.yml) when a version tag is pushed.

This workflow will open a new issue in the repository, asking the pusher to
1. double-check that the pushed tag complies with the Semantic Versioning rules described above
2. manually update `version.json` for consistency

</details>
