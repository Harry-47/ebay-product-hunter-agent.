---
name: terminal-remote-setup
description: "25 Nov 2026 - project moving off VS Code to terminal + Chrome + Remote Control; 'start the daily hunt' runs the full workflow at once; CLAUDE.md restructured; Git not yet installed"
metadata:
  type: project
---

On 2026-11-25 the user asked to run the agent on the VPS without VS Code (terminal + Chrome), controlled from the Claude mobile/desktop app with /rc, and to prepare a private GitHub repo.

**Why:** VS Code uses about 0.7 GB of the 2 GB VPS; the user works remotely.

**How to apply:** when the user types "start the daily hunt", begin immediately (CLAUDE.md section 0). Rule changes go in docs/rulebook_changelog.md plus section 0 and the affected section; supplier rules are in prompts/suppliers/. tools/ must not be renamed (guard hook path). Git and the Claude terminal CLI were not installed on 25 Nov: user installs or approves; never push or commit without being asked. Refresh claude_memory/ (emails removed) before a push. See [[operating-loop]].