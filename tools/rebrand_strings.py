"""One-off helper: replace user-facing MatlobGo strings in Dart sources."""
from __future__ import annotations

import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1] / "lib"

REPLACEMENTS: list[tuple[str, str]] = [
    ("'MatlobGo Admin'", "AppBranding.adminPanelTitle"),
    ("'MatlobGo — مندوب'", "AppBranding.driverAppName"),
    ("'MatlobGo متاح في محافظات محددة'", "'${AppBranding.shortName} متاح في محافظات محددة'"),
    ("'على أول 3 طلبات من MatlobGo'", "'على أول 3 طلبات من ${AppBranding.shortName}'"),
    ("'راجع طلبك وأكمله عبر تطبيق MatlobGo.'", "AppBranding.cartSeoDescription()"),
    ("title: 'عن MatlobGo'", "title: 'عن ${AppBranding.shortName}'"),
    (
        "'MatlobGo — منصتك لطلب الطعام والاحتياجات اليومية من مطاعm وماركتات وصيدليات في محافظتك.\\n\\n'",
        "'${AppBranding.aboutDescription}\\n\\n'",
    ),
    (
        "'MatlobGo — منصتك لطلب الطعام والاحتياجات اليومية من مطاعm وماركتات وصيدليات في محافظتك.\\n\\n'",
        "'${AppBranding.aboutDescription}\\n\\n'",
    ),
    (
        "— بيانات حية من MatlobGo.'",
        "— بيانات حية من ${AppBranding.shortName}.'",
    ),
    (
        "في $govName على MatlobGo.'",
        "في $govName على ${AppBranding.shortName}.'",
    ),
]

IMPORT_LINE = "import 'package:matlobgo/core/constants/app_branding.dart';"


def ensure_import(text: str) -> str:
    if IMPORT_LINE in text or "AppBranding." not in text:
        return text
    lines = text.splitlines()
    insert_at = 0
    for i, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = i + 1
    lines.insert(insert_at, IMPORT_LINE)
    return "\n".join(lines) + ("\n" if text.endswith("\n") else "")


def main() -> None:
    for path in ROOT.rglob("*.dart"):
        text = path.read_text(encoding="utf-8")
        original = text
        for old, new in REPLACEMENTS:
            text = text.replace(old, new)
        if text != original:
            text = ensure_import(text)
            path.write_text(text, encoding="utf-8")
            print(f"updated {path.relative_to(ROOT.parent)}")


if __name__ == "__main__":
    main()
