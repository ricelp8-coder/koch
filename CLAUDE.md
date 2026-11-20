# koch

Roblox Luau scripts (Cameraman_TD, Sorcerer_TD, Doors, Dumper, RemoteLog) plus the UI libraries in `UI/`.
Game scripts have no file extension; the loader in the diamondHub repo maps `game.GameId` to a file here.

## Defaults

- Skills in `.claude/skills/` are kept minimal to save tokens: `graphify`, `humanizer`, `debugging-and-error-recovery`, `code-review-and-quality`. Use them when they fit.
- Subagent in `.claude/agents/`: `code-reviewer`, for review-type work only.
- Use `/graphify` for codebase questions: if `graphify-out/graph.json` exists, query it first (`graphify query "<question>"`). Without a graph, a single lookup is faster with grep. Note graphify only sees files with extensions, so the extensionless game scripts are not in the graph.
- Use `humanizer` when writing prose for the user (README text, release notes).
