# koch

Roblox Luau scripts (Cameraman_TD, Sorcerer_TD, Doors, Dumper, RemoteLog) plus the UI libraries in `UI/`.
Game scripts have no file extension; the loader in the diamondHub repo maps `game.GameId` to a file here.

## Defaults

- Use the skills in `.claude/skills/` whenever one fits the task (debugging, review, spec, tests, git workflow, and so on) instead of working without them.
- Use the subagents in `.claude/agents/` (`code-reviewer`, `security-auditor`, `test-engineer`, `web-performance-auditor`) for review-type work.
- Use `/graphify` for codebase questions: if `graphify-out/graph.json` exists, query it first (`graphify query "<question>"`). Without a graph, a single lookup is faster with grep. Note graphify only sees files with extensions, so the extensionless game scripts are not in the graph.
- Use `humanizer` when writing prose for the user (README text, release notes).
