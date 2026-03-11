# rs_mdt (QBCore)

Advanced MDT resource with:
- Police MDT login/system
- EMS-only login/system tied to same backend data platform
- Adaptive dispatch automation that is suppressed when dispatchers are active

## Install
1. Copy `fivem_mdt` to your server resources as `rs_mdt`.
2. Add dependency resources: `qb-core`, `oxmysql`, `ox_lib`.
3. Import SQL: run `schema.sql`.
4. Add `ensure rs_mdt` in `server.cfg`.
5. Use `/mdt` in game.

## Dispatch model
- Calls can be manually dispatched when dispatcher players are on duty.
- If no dispatchers are online, auto-dispatch will route calls after delay.
- Delay can be configured and scales based on dispatcher count values.

## Security
- Server verifies role before creating police/EMS records.
- Dispatcher console requires configured dispatch roles/grades.
