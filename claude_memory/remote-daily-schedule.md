---
name: remote-daily-schedule
description: "User starts each hunt manually (\"run the daily hunt\") after signing in; no schedule; notify and pause on any logged-out site, resume on \"continue\""
metadata:
  node_type: memory
  type: project
  originSessionId: 534716d4-3bc7-4d6d-ac78-caa4c40c217e
  modified: 2026-10-03T16:28:35.522Z
---

The user works on a Windows Server (Chrome, VS Code and Claude Code run there). They follow and approve runs from the Claude app on a phone or tablet via Remote Control, and reach the server through Microsoft's Remote Desktop app.

2026-10-03: the user removed the daily schedule. They sign in to all sites in the server's Chrome, then write "run the daily hunt". Do not create a CronCreate schedule unless they ask again.

Logged-out rule: never research on a logged-out site. Stop on that site, send one push notification naming it, carry on with the signed-in sources, and resume that site when the user replies "continue". The agent never signs in itself.

**Why:** the user prefers to start runs themselves after confirming all logins, and doesn't want research done on logged-out sites.

**How to apply:** follow prompts/daily_hunt.md (browser research and "Starting a run" sections). See [[daily-review-page]] for where results are published.
