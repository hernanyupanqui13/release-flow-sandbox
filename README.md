# release-flow-sandbox

Private sandbox to test automatic release versioning with git-cliff before
adopting it in a real Release Flow. Every reusable workflow is a stub: nothing
is deployed, and the only credential used is the automatic `GITHUB_TOKEN`.

## Flow

Every push to `main` is deployed to qa by `qa_flow.yaml` (simulated).

Release Flow:

`compute_version` -> `validate_release` -> `deploy_stg` -> `get_last_tag`
(pushes `vX.Y.Z-rc.N`) -> `generate_pre_release` -> `promote_prd` ->
`deploy_prd` -> `generate_release` (pushes `vX.Y.Z` and the stable release).

Run it with `gh workflow run release.yaml -f simulate_failure=<stage>`, where
the stage is `none`, `stg_deploy`, `qa_rejected` or `prd_deploy`.

## Version rules

- The bump base is the latest stable `vX.Y.Z` tag; `-rc.N` tags are ignored.
- `feat` and breaking changes bump the minor version while the major is 0;
  every other commit bumps the patch.
- The release candidate number is the next free `-rc.N` for that version.
