# release-flow-sandbox

Sandbox to test automatic release versioning with git-cliff before
adopting it in a real Release Flow. Every reusable workflow is a stub: nothing
is deployed. Besides the automatic `GITHUB_TOKEN`, the only credential is the
access key of a personal Linear release pipeline.

## Flow

Every push to `main` is deployed to qa by `qa_flow.yaml` (simulated).

Release Flow (mirrors ms-ml-genai-agents-bs PR #536 and the reusable
workflows of yaperos/reusable-workflows PR #1452):

`check_branch` -> `compute_version` -> `validate_release` -> `deploy_stg`
(-> `linear_stg`) -> `get_last_tag` (pushes `vX.Y.Z-rc.N`) ->
`generate_pre_release` -> `promote_prd` -> `deploy_prd` (-> `linear_prd`) ->
`generate_release` (pushes `vX.Y.Z` and the stable release).

Start a release from main, with no release branch:

```bash
gh workflow run release.yaml --ref main -f simulate_failure=none
```

`simulate_failure` can be `none`, `stg_deploy` or `prd_deploy`. `promote_prd`
pauses until a reviewer of the `promotePRD` environment approves the prd
promotion. `linear_stg` adds the issues referenced as `[HER-123]` to the Linear
release `vX.Y.Z` in the `stg` stage; `linear_prd` completes it with the
generated release notes. Linear failures never block the deploy.

Pull request titles must follow `type(scope): description [HER-123]`, like the
gitStream rule of PR #562.

## Version rules

- The bump base is the latest stable `vX.Y.Z` tag; `-rc.N` tags are ignored.
- `feat` and breaking changes bump the minor version while the major is 0;
  every other commit bumps the patch.
- The release candidate number is the next free `-rc.N` for that version.
