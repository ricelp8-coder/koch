Copy of notpoiu/roblox-executor-mcp (MIT, see LICENSE) without node_modules, for running in Termux.

    pkg install -y nodejs git
    git clone https://github.com/ricelp8-coder/koch.git
    cd koch/roblox-executor-mcp
    npm install --omit=dev --ignore-scripts
    node dist/index.js

Executor: loadstring(game:HttpGet("http://127.0.0.1:16384/script.luau"))()
Dashboard: http://localhost:16384/
