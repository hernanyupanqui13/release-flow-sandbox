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

Start a release with `gh workflow run start_release.yaml` on main: it creates a
`release/<version>` branch and runs the Release Flow on it, because the stg, prd
and promotePRD environments only accept release/** branches. Each retry gets a
new branch (`release/vX.Y.Z-rc.N+1`). The Release Flow can also be run directly
with `gh workflow run release.yaml --ref release/<branch> -f simulate_failure=<stage>`, where
the stage is `none`, `stg_deploy` or `prd_deploy`. `promote_prd` pauses until a
reviewer of the `promotePRD` environment approves or rejects the prd promotion.

## Version rules

- The bump base is the latest stable `vX.Y.Z` tag; `-rc.N` tags are ignored.
- `feat` and breaking changes bump the minor version while the major is 0;
  every other commit bumps the patch.
- The release candidate number is the next free `-rc.N` for that version.
