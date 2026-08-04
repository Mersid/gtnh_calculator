# Local changes vs upstream

This repo tracks two branches that diverge from upstream (ShadowTheAge/gtnh):

- `main` — upstream `main` (GTNH 2.9, data format v7) + local feature commits.
- `2.8-backport` — based on `124da0e` (last commit before the 2.9 updates; this is
  the commit matching the deployed 2.8 app), with the same features cherry-picked.

The `data` submodule pins different revisions per branch (v7 data on `main`,
2.8.x data on `2.8-backport`). **Always run `git submodule update --init` after
switching branches**, and use the HTTPS override if you have no GitHub SSH keys:

```
git -c url."https://github.com/".insteadOf="git@github.com:" submodule update --init
```

A "Unsupported data version" error on page load means the submodule is out of sync
with the checked-out branch.

## Feature commits (same order on both branches)

1. **Normalize-to-1-machine button + per-recipe utilization display**
   (`main` 4ef707e / `2.8-backport` b8e6f13)
   - "Normalize to 1 machine" link in the settings panel: finds the enabled recipe
     with the highest `crafterCount`, sets its `fixedCrafterCount = 1`, clears the
     product list (product goals conflict with a fixed count), re-solves.
   - Utilization % next to each machine icon (`crafterCount / ceil(crafterCount)`),
     with a tooltip also showing utilization relative to the page bottleneck.
   - Row accent + text color by relative load: red >= 99% of max (bottleneck),
     yellow >= 50%, green otherwise.
   - Files: `src/recipeList.ts`, `assets/styles/recipe-list.css`.

2. **Infeasible-link suggestions** (`main` f962632 / `2.8-backport` 8d8c8db)
   - When the solve is infeasible, each matched link is temporarily ignored one at a
     time and re-solved; links that fix feasibility are shown as clickable icons in
     the status bar (clicking ignores that link).
   - `DiagnoseInfeasibleLinks` in `src/solver.ts`, `page.linkSuggestions`,
     rendering in `renderStatus`, action `ignore_link_suggestion`.

3. **Normalize guards + feedback** (`main` 3c0b6f7 + 2c5b4e2 / `2.8-backport` d02cb1c + 5d93e65)
   - Normalize refuses to run unless the page status is "solved" and some machine
     count is > 0, with an explanatory alert otherwise. Prevents normalizing from
     garbage infeasible/all-zero states (which previously pinned an arbitrary
     machine and inflated the rest of the chain).

4. **Enable/disable toggle for recipes and groups**
   (`main` c0aa84a / `2.8-backport` cherry-pick, see log)
   - `disabled` flag on `RecipeGroupEntry` (recipes and groups), serialized only
     when true. Disabled subtrees are skipped when building the LP model
     (`CreateAndMatchLinks`) and when collecting diagnostic link candidates.
   - "on/off" toggle button in the action cell of recipe rows, collapsed groups,
     and expanded group headers. Disabled entries render dimmed and solve as zero.
   - Files: `src/page.ts`, `src/solver.ts`, `src/recipeList.ts`,
     `assets/styles/recipe-list.css`.

## Porting notes

- Cherry-picks between branches have applied cleanly so far (`recipeList.ts` and
  `solver.ts` barely diverged between the bases). Procedure:
  commit on `main`, `git checkout 2.8-backport`, `git cherry-pick main`,
  `git submodule update --init`, `npm run build`, `npx jest`.
- Test baselines: `main` = 33/33 pass. `2.8-backport` = 34/35 with one
  pre-existing snapshot failure ("UHV naqfuel mk3 chromatic glass") that also
  fails on the untouched base commit `124da0e` — not caused by local changes.
- `package-lock.json` has incidental local npm noise (uncommitted); `.idea/` and
  `dist/` are not tracked. Nothing has been pushed to origin.
