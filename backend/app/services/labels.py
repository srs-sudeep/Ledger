from __future__ import annotations


TRANSLATIONS: list[tuple[str, str]] = [
    ("地方税", "Local tax"),
    ("国税", "National tax"),
    ("税引前利息", "Pre-tax interest"),
    ("振込手数料", "Bank transfer fee"),
    ("現金出金", "ATM cash withdrawal"),
    ("現金入金", "ATM cash deposit"),
    ("振込", "Bank transfer"),
    ("給与", "Salary"),
    ("ファミリーマート", "FamilyMart"),
    ("ダイソー", "Daiso"),
    ("ゴヴィンダス", "Govinda's"),
    ("スワガット", "Swagat"),
    ("ナンディニ", "Nandhini"),
    ("マツモトキヨシ", "Matsumoto Kiyoshi"),
    ("ボンベイカフェ", "Bombay Cafe"),
]


def translate_label(value: str | None) -> str | None:
    text = (value or "").strip()
    if not text:
        return None
    translated = text
    for src, dst in TRANSLATIONS:
        translated = translated.replace(src, dst)
    return translated
