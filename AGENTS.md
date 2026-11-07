# BookMate development rules

- Preserve existing behavior and user data. Debug builds use staging; Release uses production. Verify the built app environment before device installation. Do not reset app data or write production data during development.
- Create a feature branch and a focused PR for each independently reviewable change. Use stacked PRs with explicit base branches when changes depend on one another. Do not bundle unrelated settings or tooling changes. Do not merge without authorization for the current delivery.
- PR descriptions explain the user-visible problem, resulting behavior, architecture implications, observed validation, and material limitations. Keep descriptions about the project; omit learning status and tool/model branding.
- Follow MVVM + Repository + DI. Inject repositories through AppDependencies. Keep networking and persistence outside Views. Keep renderer/camera concerns separate from application data and navigation.
- Use applicable installed design/review/testing guidance. Verify rendered native UI in light and dark appearance, and preserve accessibility labels and touch targets when removing visible labels.
- Use quiet content surfaces, shared 24 pt card and 18 pt input rounding (covers 8 pt), consistent book covers without colored backing pads, and native glass for floating controls. Home recent-word content has no backing card or border. Keep the default background neutral/cool and accent blue clear. Avoid decorative gradients, colored glows, and nested cards. Discuss major unrequested visual changes before implementation.
- Run meaningful regression tests for changed behavior and relevant build/UI checks. Record actual results and untested limits separately. Keep secrets and test credentials out of logs and PRs.

## Pull request presentation

- Use Conventional Commit titles with a non-empty scope: `feat(room): ...` for features, `fix(auth): ...` for fixes, `refactor(ui): ...` for refactors, and `test(room): ...` or `docs(pr): ...` for test/documentation changes. Always include parentheses and scope. Write the summary in Korean.
- Follow `.github/pull_request_template.md`: existing problem, changes and design reasons, actual verification, remaining limits and review focus. Explain ownership boundaries and include a small data-flow diagram when useful.
- Separate local tests, simulator/UI checks, physical-device installation and GitHub CI. Distinguish isolated PR validation from later integrated tests, historical records from new execution, and installation from physical interaction testing.
- Keep failed/pending/skipped/untested checks explicit. Replace stale progress notes with one coherent current report; do not append contradictory updates.
- State base PR/branch and merge order for stacked PRs. Use repository permalinks, test names and CI links, not local absolute paths, as public review evidence.
