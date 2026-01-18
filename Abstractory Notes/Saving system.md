[[GameState]] has the top-level save/load methods.

A save game includes the scene that should be loaded, all the GameState data, and data that needs to be passed into the loaded scene once it's loaded.

Many pieces of info use var_to_str() to save and str_to_var() to load.

Structure of saved dictionary:
- "scene_index": index that identifies what scene should be loaded. Associated in [[Consts]].SCENE_FILES
- "scene_data": Dictionary from the main scene node. Structure varies with scene
- "upgrade_tree": Dictionary from [[UpgradeTree]] class.