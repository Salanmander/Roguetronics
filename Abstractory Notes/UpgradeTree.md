Contains [[Upgrade]] information. all_upgrades stores upgrade objects, and upgrades_obtained and upgrades_unobtained contain indices into that.

Information about upgrades is loaded from res://Rewards/upgrades.json on initialization of class.

Contains save/load processing for upgrade state.
Structure of save dictionary:
- "obtained": array of obtained upgrade indices. Order in which they are obtained is preserved.
- "unobtained": array of upgrades that haven't been obtained. This redundancy is in hopes of being able to deal with version mismatches.