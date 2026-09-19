from pathlib import Path

IMPORT = "import 'package:matlobgo/core/constants/app_branding.dart';"


def add_import(text: str) -> str:
    if IMPORT in text or "AppBranding." not in text:
        return text
    lines = text.splitlines()
    idx = max(i for i, l in enumerate(lines) if l.startswith("import "))
    lines.insert(idx + 1, IMPORT)
    suffix = "\n" if text.endswith("\n") else ""
    return "\n".join(lines) + suffix


def patch(path: Path, transform) -> None:
    text = path.read_text(encoding="utf-8")
    new_text = transform(text)
    if new_text != text:
        new_text = add_import(new_text)
        path.write_text(new_text, encoding="utf-8")
        print("patched", path.name)


# profile_tab
p = Path(r"c:\Users\Techno Shield\StudioProjects\MatlobGo\MatlobGo\lib\screens\home\tabs\profile_tab.dart")
t = p.read_text(encoding="utf-8")
t = t.replace("title: 'عن MatlobGo'", "title: 'عن ${AppBranding.shortName}'")
for line in t.splitlines():
    if line.strip().startswith("'MatlobGo — منصتك"):
        old_line = line
        indent = line[: len(line) - len(line.lstrip())]
        t = t.replace(old_line, f"{indent}'${{AppBranding.aboutDescription}}\\n\\n'")
        break
patch(p, lambda _: t)

patch(
    Path(r"c:\Users\Techno Shield\StudioProjects\MatlobGo\MatlobGo\lib\web\screens\web_home_screen.dart"),
    lambda t: t.replace("من MatlobGo.'", "من ${AppBranding.shortName}.'"),
)
patch(
    Path(r"c:\Users\Techno Shield\StudioProjects\MatlobGo\MatlobGo\lib\web\screens\web_category_screen.dart"),
    lambda t: t.replace("على MatlobGo.'", "على ${AppBranding.shortName}.'"),
)
patch(
    Path(r"c:\Users\Techno Shield\StudioProjects\MatlobGo\MatlobGo\lib\web\screens\web_cart_screen.dart"),
    lambda t: t.replace(
        "description: 'راجع طلبك وأكمله عبر تطبيق MatlobGo.',",
        "description: AppBranding.cartSeoDescription(),",
    ),
)
patch(
    Path(r"c:\Users\Techno Shield\StudioProjects\MatlobGo\MatlobGo\lib\screens\home\widgets\governorate_picker.dart"),
    lambda t: t.replace(
        "'MatlobGo متاح في محافظات محددة'",
        "'${AppBranding.shortName} متاح في محافظات محددة'",
    ),
)
patch(
    Path(r"c:\Users\Techno Shield\StudioProjects\MatlobGo\MatlobGo\lib\data\mock_home_data.dart"),
    lambda t: t.replace(
        "'على أول 3 طلبات من MatlobGo'",
        "'على أول 3 طلبات من ${AppBranding.shortName}'",
    ),
)
patch(
    Path(r"c:\Users\Techno Shield\StudioProjects\MatlobGo\MatlobGo\lib\main_delivery.dart"),
    lambda t: t.replace("'MatlobGo — مندوب'", "AppBranding.driverAppName"),
)

print("done")
