bl_info = {
    "name": "Bo Blender Config",
    "author": "Bohdon Sayre",
    "version": (1, 0, 0),
    "blender": (5, 2, 0),
    "location": "Preferences > Keymap > Add-ons",
    "description": "Core settings and keymaps for Maya/Unreal-friendly control",
    "category": "Interface",
}

import bpy

# default entries to disable, matched by operator id, mouse button, and modifiers
DISABLE_TARGETS = [
    (
        # Alt+LMB paints Mask in sculpt, disable it to keep camera control
        "Sculpt",
        "sculpt.brush_stroke",
        "LEFTMOUSE",
        dict(shift=False, ctrl=False, alt=True, oskey=False),
    ),
]
disabled_items = []  # kmi refs that were disabled - restored on unregister

# custom key maps for Maya/Unreal-style navigation
# (keymap name, space_type, [(operator idname, mouse button), ...])
# CLICK_DRAG + Alt is used everywhere so a plain Alt+Click still works for loop-select
NAV_TARGETS = [
    # generic, shared 3D nav
    (
        "3D View",
        "VIEW_3D",
        [
            ("view3d.rotate", "LEFTMOUSE"),
            ("view3d.move", "MIDDLEMOUSE"),
            ("view3d.zoom", "RIGHTMOUSE"),
        ],
    ),
    # generic, shared 2D nav
    (
        "View2D",
        "EMPTY",
        [
            ("view2d.pan", "MIDDLEMOUSE"),
            ("view2d.zoom", "RIGHTMOUSE"),
        ],
    ),
    # sculpt mode has its own keymap, higher prio than "3D View"
    (
        "Sculpt",
        "VIEW_3D",
        [
            ("view3d.rotate", "LEFTMOUSE"),
            ("view3d.move", "MIDDLEMOUSE"),
            ("view3d.zoom", "RIGHTMOUSE"),
        ],
    ),
    # image editor, covers both the render view and UV editing
    (
        "Image",
        "IMAGE_EDITOR",
        [
            ("image.view_pan", "MIDDLEMOUSE"),
            ("image.view_zoom", "RIGHTMOUSE"),
        ],
    ),
]
addon_keymaps = []  # (km, kmi) pairs that were added

# prevent LMB=Confirm and RMB=Cancel from working while Alt is pressed,
# so nav controls can be fully used even during move/rotate/scale ops.
MODAL_ALT_EXCLUDE = [
    ("Transform Modal Map", "Confirm", "LEFTMOUSE"),
    ("Transform Modal Map", "Cancel", "RIGHTMOUSE"),
]
modal_overrides = []  # (kmi, original_any, original_alt) - restored on unregister

# excluding Alt from Confirm/Cancel above only stops those actions from
# firing, use PASS_THROUGH to prevent the modal from swallowing the input
# so it reaches the regular keymaps
MODAL_PASS_THROUGH = ["LEFTMOUSE", "RIGHTMOUSE"]
modal_pass_through_items = []  # (km, kmi) - removed on unregister


def _modifiers_match(kmi, mods):
    return (
        kmi.shift == mods["shift"]
        and kmi.ctrl == mods["ctrl"]
        and kmi.alt == mods["alt"]
        and kmi.oskey == mods["oskey"]
    )


def register():
    wm = bpy.context.window_manager

    # add Maya-style camera controls
    kc = wm.keyconfigs.addon
    if kc:
        for km_name, space_type, bindings in NAV_TARGETS:
            km = kc.keymaps.new(name=km_name, space_type=space_type)
            for idname, button in bindings:
                kmi = km.keymap_items.new(idname, button, "CLICK_DRAG", alt=True)
                addon_keymaps.append((km, kmi))

    # update user config (more permanent than just this addon, but effects are reversed on unregister)
    user_kc = wm.keyconfigs.user

    # disable unwanted default bindings
    if user_kc:
        for km_name, idname, mouse_type, mods in DISABLE_TARGETS:
            km = user_kc.keymaps.get(km_name)
            if not km:
                continue
            for kmi in km.keymap_items:
                if kmi.idname == idname and kmi.type == mouse_type and _modifiers_match(kmi, mods):
                    if kmi.active:
                        kmi.active = False
                        disabled_items.append(kmi)

    # stop transform modal confirm/cancel from eating camera controls
    if user_kc:
        for km_name, propvalue, mouse_type in MODAL_ALT_EXCLUDE:
            km = user_kc.keymaps.get(km_name)
            if not km:
                continue
            for kmi in km.keymap_items:
                if getattr(kmi, "propvalue", "") == propvalue and kmi.type == mouse_type:
                    modal_overrides.append((kmi, kmi.any, kmi.alt))
                    kmi.any = False
                    kmi.alt = False

    # add explicit pass-through so those freed-up events reach view3d.rotate/zoom
    tkm = user_kc.keymaps.get("Transform Modal Map") if user_kc else None
    if tkm:
        for mouse_type in MODAL_PASS_THROUGH:
            # PRESS (not CLICK_DRAG) so there's no gap between button-down and drag-threshold.
            kmi = tkm.keymap_items.new_modal("PASS_THROUGH", mouse_type, "PRESS", alt=True)
            modal_pass_through_items.append((tkm, kmi))


def unregister():
    for km, kmi in addon_keymaps:
        try:
            km.keymap_items.remove(kmi)
        except RuntimeError:
            pass
    addon_keymaps.clear()

    for km, kmi in modal_pass_through_items:
        try:
            km.keymap_items.remove(kmi)
        except RuntimeError:
            pass
    modal_pass_through_items.clear()

    for kmi in disabled_items:
        kmi.active = True
    disabled_items.clear()

    for kmi, orig_any, orig_alt in modal_overrides:
        kmi.any = orig_any
        kmi.alt = orig_alt
    modal_overrides.clear()


if __name__ == "__main__":
    register()
