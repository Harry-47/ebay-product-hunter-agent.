---
name: drive-daily-hunt-upload
description: "User wants the daily hunt Excel workbook uploaded to Google Drive folder \"Daily hunt files\" after every hunt; connector can't upload binary .xlsx"
metadata:
  node_type: memory
  type: reference
  originSessionId: 534716d4-3bc7-4d6d-ac78-caa4c40c217e
  modified: 2026-10-06T17:22:28.977Z
---

Drive folder "Daily hunt files" (<email removed>): id `1XmZjihCuoraQjxYyPY7xtgrYNlUuA5xe`, https://drive.google.com/drive/folders/1XmZjihCuoraQjxYyPY7xtgrYNlUuA5xe

User instruction (2026-10-06): upload the daily hunt files to this folder, always, from now on; they want the **Excel workbooks** (`data/daily/YYYY-MM-DD[_runN]_ebay_product_hunt.xlsx`).

**Constraint found:** the Google Drive connector `create_file` only takes pasted text/base64 (no local path). The .xlsx files are 34-72 KB, so base64 copy through the model is large and error-prone. No Drive for desktop on the server. Claude in Chrome file upload is disabled by the project guard.

Uploaded so far (3 Oct only, text versions): `2026-10-03_run2_summary` (condensed doc, superseded), `2026-10-03_run2_summary_full`, `2026-10-03_run2_candidates` (Sheet), `2026-10-03_run2_rejections_trimmed` (Sheet).

**How to apply:** after each hunt, tell the user the workbook path and ask how to upload it (or use the method they chose). If they install Drive for desktop and sync the folder, copy the workbook there with PowerShell. Do not paste base64 of the workbook.
