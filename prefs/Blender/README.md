# Bo Blender Config

Run this script in Blender to install

```py
import bpy, os, sys
from pathlib import Path


def install_workspace_config():
    scripts = Path(os.path.expanduser("~/workspace/prefs/Blender/scripts"))
    addons = scripts / "addons"
    sd = bpy.context.preferences.filepaths.script_directories.new()
    sd.name = "workspace"
    sd.directory = str(scripts)
    sys.path.append(str(addons))
    bpy.ops.extensions.repo_refresh_all()
    bpy.ops.preferences.addon_enable(module="bo_blender_config")
    bpy.ops.wm.save_userpref()


install_workspace_config()
```
