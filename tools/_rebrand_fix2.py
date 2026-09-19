from pathlib import Path

IMPORT = "import 'package:matlobgo/core/constants/app_branding.dart';"

TARGETS = [
    Path(r"c:\Users\Techno Shield\StudioProjects\MatlobGo\MatlobGo\lib\screens\home\tabs\profile_tab.dart"),
    Path(r"c:\Users\Techno Shield\StudioProjects\MatlobGo\MatlobGo\lib\models\app_settings.dart"),
    Path(r"c:\Users\Techno Shield\StudioProjects\MatlobGo\MatlobGo\lib\screens\service_area\service_area_unsupported_screen.dart"),
    Path(r"c:\Users\Techno Shield\StudioProjects\MatlobGo\MatlobGo\lib\screens\service_area\service_area_onboarding_screen.dart"),
    Path(r"c:\Users\Techno Shield\StudioProjects\MatlobGo\MatlobGo\lib\screens\home\widgets\profile_widgets.dart"),
    Path(r"c:\Users\Techno Shield\StudioProjects\MatlobGo\MatlobGo\lib\models\cms_text_entry.dart"),
    Path(r"c:\Users\Techno Shield\StudioProjects\MatlobGo\MatlobGo\lib\admin\widgets\admin_settings_panel.dart"),
]

REPLACEMENTS = [
    ("MatlobGo Plus", "${AppBranding.shortName} Plus"),
    ("MatlobGo", "${AppBranding.shortName}"),
]


def add_import(text: str) -> str:
    if IMPORT in text or "${AppBranding." not in text:
        return text
    lines = text.splitlines()
    idx = max(i for i, l in enumerate(lines) if l.startswith("import "))
    lines.insert(idx + 1, IMPORT)
    return "\n".join(lines) + ("\n" if text.endswith("\n") else "")


for path in TARGETS:
    text = path.read_text(encoding="utf-8")
    orig = text
    for old, new in REPLACEMENTS:
        if "package:matlobgo" in old:
            continue
        # Skip dart imports
        lines = text.splitlines()
        out = []
        for line in lines:
            if line.strip().startswith("import ") or line.strip().startswith("export "):
                out.append(line)
            else:
                out.append(line.replace(old, new))
        text = "\n".join(out) + ("\n" if orig.endswith("\n") else "")
    if text != orig:
        text = add_import(text)
        path.write_text(text, encoding="utf-8")
        print("patched", path.name)

print("done")
