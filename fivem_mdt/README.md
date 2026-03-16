# rs_mdt (QBCore)

Advanced MDT resource with:
- Police MDT login/system and EMS-only login tied to same backend platform
- Adaptive dispatch automation suppressed when dispatchers are active
- **Supervisor-managed SQL MDT accounts** (username/password set per officer)
- Suspect biometrics/intel records (photo, fingerprint, DNA, risk, parole, notes)
- Officer roster management with rank, portrait, and badge image assignment
- Live bodycam directory with stream links inside MDT
- Charge catalog management, case creation, complex reports, and digital/physical evidence workflows
- **Dispatcher live map** with active unit tracking and SQL-backed call markers/cards
- **Phone-to-Discord bridge** for 911/call events

## Install
1. Copy `fivem_mdt` to your server resources as `rs_mdt`.
2. Add dependency resources: `qb-core`, `oxmysql`.
3. Import SQL: run `schema.sql`.
4. Add `ensure rs_mdt` in `server.cfg`.
5. Use `/mdt` in game.

## SQL MDT Accounts
- Supervisors (configured by `Config.Supervisor.minPoliceGrade`) can set/reset MDT SQL logins.
- Accounts are stored in `mdt_accounts` with SHA2 password hashes.
- If auth is enabled (`Config.MDTAuth.enabled`), users must log in before seeing MDT data.

## Dispatcher live map
- Units publish coordinates periodically and are rendered on dispatcher map canvas.
- Active calls are stored in SQL (`mdt_dispatch_calls`) and displayed as dispatcher cards that can be opened/resolved.
- Active calls are displayed with map markers and can be resolved from dispatcher UI.

## Phone + Discord bridge
- Trigger server event `rs_mdt:server:phone911` from your phone script with call payload.
- Configure `Config.Discord.webhook911` and enable `Config.Discord.enabled = true`.
- Each incoming call is mirrored to Discord as an embed.

## Security
- Server verifies role before creating/updating police/EMS/investigation records.
- Dispatcher console requires configured dispatch roles/grades.

## GitHub download / releases
- This repo includes a GitHub Actions workflow (`.github/workflows/release-rs-mdt.yml`) that builds `rs_mdt.zip` from `fivem_mdt/`.
- To create a downloadable release ZIP on GitHub:
  1. Push this repo to GitHub.
  2. Create and push a tag like `rs_mdt-v1.0.0`.
  3. The workflow publishes `dist/rs_mdt.zip` as a release asset.
- You can also run `./scripts/package_rs_mdt.sh` locally to generate `dist/rs_mdt.zip`.
