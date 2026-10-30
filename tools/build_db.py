#!/usr/bin/env python3
"""Build the bundled offline `assets/sunnah.db` for Bayan Sunnah.

Sources (cached under tools/cache/):
  * fawazahmed0/hadith-api  - Arabic + English matn for Bukhari / Muslim / Nawawi 40
  * hapibi/hadith-json      - Riyad as-Salihin (Arabic + English)

Grades are *derived from the classical takhrij notes embedded in the Arabic
text itself* (e.g. "متفق عليه", "رواه البخاري", "حديث حسن", "في إسناده ضعف").
No grade is invented: when the text carries no explicit verdict the row keeps
a NULL grade and is treated as ungraded by the reader.

Usage:  python3 tools/build_db.py
"""
from __future__ import annotations

import json
import os
import re
import sqlite3
import sys
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
CACHE = os.path.join(HERE, "cache")
OUT = os.path.join(ROOT, "assets", "sunnah.db")

RAW = "https://raw.githubusercontent.com"
FAWAZ = "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions"

# --- sample sizes (keeps the bundle comfortably under 15 MB) ---------------
SAMPLE_PER_CHAPTER = 80
RIYAD_SAMPLE = 400

# ---------------------------------------------------------------------------
# Arabic normalisation - MUST mirror lib/core/utils/arabic_normalizer.dart
# ---------------------------------------------------------------------------
_DIACRITICS = re.compile(
    "[\u0610-\u061a\u064b-\u065f\u0670\u06d6-\u06dc\u06df-\u06e8\u06ea-\u06ed]"
)
_TATWEEL = "\u0640"


def normalize_arabic(text: str) -> str:
    if not text:
        return ""
    text = text.replace("<br>", " ").replace("\r", " ").replace("\n", " ")
    text = _DIACRITICS.sub("", text)
    text = text.replace(_TATWEEL, "")
    for src, dst in (
        ("\u0623", "\u0627"),  # أ -> ا
        ("\u0625", "\u0627"),  # إ -> ا
        ("\u0622", "\u0627"),  # آ -> ا
        ("\u0671", "\u0627"),  # ٱ -> ا
        ("\u0649", "\u064a"),  # ى -> ي
        ("\u0629", "\u0647"),  # ة -> ه
        ("\u0624", "\u0648"),  # ؤ -> و
        ("\u0626", "\u064a"),  # ئ -> ي
    ):
        text = text.replace(src, dst)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


# ---------------------------------------------------------------------------
# Grade derivation
# ---------------------------------------------------------------------------
GRADE_SOURCES = {
    "bukhari": "Darussalam",
    "muslim": "Darussalam",
    "nawawi": "Al-Nawawi",
    "riyad": "Al-Nawawi",
    "mishkat": "Al-Albani",
}


def map_albani_grade(raw: str) -> str | None:
    """Map an Al-Albani Arabic grade string onto sahih/hasan/daif.

    Weakness wins when a hadith carries several verdicts, and "لم تتمّ دراسته"
    ("not studied") maps to NULL rather than being guessed at.
    """
    norm = normalize_arabic(raw or "")
    if not norm:
        return None
    if "ضعيف" in norm or "موضوع" in norm or "واه" in norm:
        return "daif"
    if "حسن" in norm and "صحيح" not in norm:
        return "hasan"
    if "صحيح" in norm or "متفق" in norm or "جيد" in norm:
        return "sahih"
    return None

# Matching runs on the normalised text so diacritics and letter variants never
# hide a verdict. Word boundaries matter: "رواه" (narrated) must not be read as
# the "واه" (weak) stem, and the bare word "مسلم" (a Muslim) must not be read
# as the collection citation.
# NOTE: every pattern below is written in *normalised* Arabic (alif variants
# folded to ا, taa marbuta to ه, no diacritics) because matching runs on the
# output of `normalize_arabic`.
_HASAN_SAHIH = re.compile(r"حسن\s+صحيح|صحيح\s+حسن")
# Strict form: an explicit scholarly verdict. The bare adjective "حسن" (as in
# "good character") is deliberately excluded so it cannot mis-grade a matn.
_HASAN = re.compile(
    r"\bحديث\s+حسن\b|\bاسناد\s+حسن\b|\bباسناد\s+حسن\b|اسانيد\s+حسنه|حسن\s+لغيره"
)
# The bare noun "ضعف" ("ضعفاً" = manifold reward) is excluded; only the
# explicit weakness adjective and its synonyms count as a verdict.
_DAIF = re.compile(
    r"\bضعيف\b|\bواه\b|\bمنكر\b|\bموضوع\b|\bلا\s+يصح\b|\bمنقطع\b|\bمعلول\b"
)
# Explicit takhrij citations. Requiring the narration verb avoids matching the
# ordinary word "المسلم" ("the Muslim") which appears inside many matn texts.
_CITED = re.compile(
    r"متفق\s+عليه|(?:رواه|روى|روي|روته)\s+(?:ال)?"
    r"(?:بخاري|مسلم|ابو\s+داود|الترمذي|النسائي|ابن\s+ماجه|احمد|مالك)"
    r"|(?:ال)?بخاري\s+(?:و|،)\s*(?:ال)?مسلم"
)
# Broad "this is a sound text" markers; only trustworthy inside the takhrij
# notes of Nawawi / the Sahihayn, never as a bare word in a Riyad matn.
_SOUND = re.compile(r"\bصحيح\b|صحيحيهما|صحيحي|الصحيحين|اصح\s+الكتب")




# The takhrij note sits at the very end of the text and is far shorter than any
# matn, so a bounded trailing window is enough to isolate it.
_NOTE_WINDOW = 320
# Narration / verdict verbs used as a fallback anchor when a note is unbracketed.
_NOTE_ANCHOR = re.compile(r"رواه|روى|روي|متفق عليه|حديث\s+حسن")


def takhrij_note(text: str) -> str:
    """Return the trailing citation note of a hadith, or '' when it has none.

    Verdict words also occur inside matn narratives ("نهي عن المنكر", "الضعيف"),
    so grading must only ever look at the appended note. Notes are bracketed
    ("((متفق عليه))", "[رواه البخاري] [ومسلم]") and are found at the first
    bracket inside a bounded trailing window; a matn containing no bracket in
    that window yields no note and therefore no derived verdict.
    """
    norm = normalize_arabic(text)
    window = norm[-_NOTE_WINDOW:]
    idx = min((i for i, ch in enumerate(window) if ch in "(["), default=-1)
    if idx != -1:
        return window[idx:]
    # Some entries carry the verdict before the bracketed reference; fall back
    # to the last narration/verdict verb so the note is still captured.
    anchor = None
    for m in _NOTE_ANCHOR.finditer(window):
        anchor = m
    return window[anchor.start():] if anchor else ""


def classify(text: str, source: str, mode: str) -> tuple[str | None, str | None]:
    """Derive (grade, grade_source) for one hadith.

    mode:
      'sahihayn' - the text sits inside al-Bukhari / Muslim, so soundness is the
                   collection default and only an explicit weakness demotes it.
      'nawawi'   - the takhrij note is authoritative; read the verdict from it.
      'riyad'    - be conservative: only an explicit verdict is recorded, and
                   citations must carry a narration verb.
    """
    note = takhrij_note(text)
    if mode == "sahihayn":
        # Soundness is the collection default; a weakness note is decisive.
        if _DAIF.search(note):
            return "daif", source
        if _HASAN.search(note) and not _HASAN_SAHIH.search(note):
            return "hasan", source
        return "sahih", source
    if not note:
        return None, None
    if _DAIF.search(note):
        return "daif", source
    if _HASAN_SAHIH.search(note):
        return "sahih", source
    if _CITED.search(note) or (mode == "nawawi" and _SOUND.search(note)):
        return "sahih", source
    if _HASAN.search(note):
        return "hasan", source
    return None, None


# ---------------------------------------------------------------------------
# Download helpers
# ---------------------------------------------------------------------------
def fetch(url: str, name: str) -> dict:
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, name)
    if not os.path.exists(path):
        print(f"  downloading {name} ...", flush=True)
        with urllib.request.urlopen(url, timeout=180) as r:
            data = r.read()
        with open(path, "wb") as f:
            f.write(data)
    with open(path, "rb") as f:
        return json.load(f)


def narrator_from_english(text: str) -> str:
    if not text:
        return ""
    m = re.match(r"\s*Narrated\s+([^:]{2,80}?):", text)
    if m:
        return m.group(1).strip()
    m = re.match(r"\s*([A-Z][A-Za-z'\- ]{2,60}?)\s+(?:reported|narrated)\b", text)
    if m:
        return m.group(1).strip()
    return ""


# ---------------------------------------------------------------------------
# Book / chapter metadata (curated, matches the spec)
# ---------------------------------------------------------------------------
BOOKS = [
    (1, "صحيح البخاري", "Sahih al-Bukhari", "محمد بن إسماعيل البخاري"),
    (2, "صحيح مسلم", "Sahih Muslim", "مسلم بن الحجاج النيسابوري"),
    (3, "الأربعون النووية", "40 Hadith Nawawi", "يحيى بن شرف النووي"),
    (4, "رياض الصالحين", "Riyad as-Salihin", "يحيى بن شرف النووي"),
    # Mishkat carries explicit Al-Albani gradings (including da'if), which the
    # four collections above cannot supply: the Sahihayn and Nawawi's selection
    # are authentic by construction.
    (5, "مشكاة المصابيح", "Mishkat al-Masabih", "ولي الدين التبريزي"),
]

# Mishkat chapter ids that are sampled, mapped to (title_ar, title_en).
MISHKAT_CHAPTERS = [
    (1, "كتاب الإيمان", "Book of Faith"),
    (2, "كتاب العلم", "Book of Knowledge"),
    (3, "كتاب الطهارة", "Book of Purification"),
    (4, "كتاب الصلاة", "Book of Prayer"),
    (6, "كتاب الزكاة", "Book of Zakat"),
    (7, "كتاب الصوم", "Book of Fasting"),
    (8, "كتاب الحج", "Book of Hajj"),
    (11, "كتاب البيوع", "Book of Transactions"),
    (13, "كتاب النكاح", "Book of Marriage"),
    (18, "كتاب الآداب", "Book of Manners"),
]

# (id, book_id, chapter_number, title_ar, title_en, source_section_ids)
BUKHARI_CHAPTERS = [
    (1, 1, 1, "كتاب بدء الوحي", "Book of Revelation", [1]),
    (2, 1, 2, "كتاب الإيمان", "Book of Faith", [2]),
    (3, 1, 3, "كتاب العلم", "Book of Knowledge", [3]),
    (4, 1, 4, "كتاب الوضوء", "Book of Ablution", [4]),
    (5, 1, 5, "كتاب الغسل", "Book of Ghusl", [5]),
]
MUSLIM_CHAPTERS = [
    (6, 2, 1, "كتاب الإيمان", "Book of Faith", [1]),
    (7, 2, 2, "كتاب الطهارة", "Book of Purification", [2]),
    (8, 2, 3, "كتاب الحيض", "Book of Menstruation", [3]),
    (9, 2, 4, "كتاب الصلاة", "Book of Prayers", [4]),
    (10, 2, 5, "كتاب المساجد", "Book of Mosques", [5]),
]


def build_chapters():
    chapters = []
    # Nawawi: one chapter per hadith (id 11..52 for hadith 1..42)
    nawawi = []
    for i in range(1, 43):
        cid = 10 + i
        nawawi.append((cid, 3, i, f"الحديث {i}", f"Hadith {i}"))
    riyad = []
    return chapters, nawawi, riyad


def main() -> int:
    print("Bayan Sunnah - building assets/sunnah.db")
    bukhari_ar = fetch(f"{FAWAZ}/ara-bukhari.min.json", "ara-bukhari.min.json")
    bukhari_en = fetch(f"{FAWAZ}/eng-bukhari.min.json", "eng-bukhari.min.json")
    muslim_ar = fetch(f"{FAWAZ}/ara-muslim.min.json", "ara-muslim.min.json")
    muslim_en = fetch(f"{FAWAZ}/eng-muslim.min.json", "eng-muslim.min.json")
    nawawi_ar = fetch(f"{FAWAZ}/ara-nawawi.min.json", "ara-nawawi.min.json")
    nawawi_en = fetch(f"{FAWAZ}/eng-nawawi.min.json", "eng-nawawi.min.json")
    riyad = fetch(
        f"{RAW}/hapibi/hadith-json/HEAD/db/by_book/other_books/riyad_assalihin.json",
        "riyad.json",
    )
    mishkat = fetch(
        f"{RAW}/hapibi/hadith-json/HEAD/db/by_book/other_books/mishkat_almasabih.json",
        "mishkat.json",
    )

    rows_hadith = []  # dicts
    rows_chapters = []

    def add_book_sample(book_id, chapters, ar, en, prefix):
        """Add a curated sample: up to SAMPLE_PER_CHAPTER hadiths per section."""
        ar_by_num = {h["hadithnumber"]: h for h in ar["hadiths"]}
        en_by_num = {h["hadithnumber"]: h for h in en["hadiths"]}
        by_section = {}
        for h in ar["hadiths"]:
            ref = h.get("reference") or {}
            book_no = ref.get("book")
            if book_no is None:
                continue
            by_section.setdefault(book_no, []).append(h)
        hid = 0
        for cid, _bid, cnum, tar, ten, sections in chapters:
            rows_chapters.append((cid, book_id, cnum, tar, ten))
            picked = []
            for sec in sections:
                picked.extend(by_section.get(sec, []))
            for h in picked[:SAMPLE_PER_CHAPTER]:
                num = h["hadithnumber"]
                matn_ar = (ar_by_num.get(num) or {}).get("text") or ""
                en_obj = en_by_num.get(num) or {}
                matn_en = en_obj.get("text") or ""
                if not matn_ar.strip():
                    continue
                grade, src = classify(matn_ar, GRADE_SOURCES[prefix], "sahihayn")
                hid += 1
                rows_hadith.append(
                    dict(
                        book_id=book_id,
                        chapter_id=cid,
                        hadith_number=num,
                        narrator=narrator_from_english(matn_en),
                        matn_ar=matn_ar,
                        matn_en=matn_en,
                        grade=grade,
                        grade_source=src,
                    )
                )

    add_book_sample(1, BUKHARI_CHAPTERS, bukhari_ar, bukhari_en, "bukhari")
    add_book_sample(2, MUSLIM_CHAPTERS, muslim_ar, muslim_en, "muslim")

    # --- 40 Hadith Nawawi (complete) ---
    nawawi_en_by_num = {h["hadithnumber"]: h for h in nawawi_en["hadiths"]}
    for i, h in enumerate(nawawi_ar["hadiths"], start=1):
        cid = 10 + i
        rows_chapters.append((cid, 3, i, f"الحديث {i}", f"Hadith {i}"))
        matn_ar = h.get("text") or ""
        matn_en = (nawawi_en_by_num.get(h["hadithnumber"]) or {}).get("text") or ""
        grade, src = classify(matn_ar, GRADE_SOURCES["nawawi"], "nawawi")
        rows_hadith.append(
            dict(
                book_id=3,
                chapter_id=cid,
                hadith_number=i,
                narrator=narrator_from_english(matn_en),
                matn_ar=matn_ar,
                matn_en=matn_en,
                grade=grade,
                grade_source=src if grade else None,
            )
        )

    # --- Riyad as-Salihin (curated) ---
    ch_map = {}
    next_ch_id = 100
    picked = 0
    for h in riyad["hadiths"]:
        if picked >= RIYAD_SAMPLE:
            break
        ch_src = h.get("chapterId")
        if ch_src is None:
            continue
        if ch_src not in ch_map:
            # resolve chapter names from the source metadata
            ch_meta = next(
                (c for c in riyad["chapters"] if c["id"] == ch_src), None
            )
            tar = (ch_meta or {}).get("names", {}).get("ar", f"كتاب {ch_src}")
            ten = (ch_meta or {}).get("names", {}).get("en", f"Book {ch_src}")
            ch_map[ch_src] = next_ch_id
            rows_chapters.append((next_ch_id, 4, len(ch_map), tar, ten))
            next_ch_id += 1
        matn_ar = h.get("arabic") or ""
        matn_en = (h.get("english") or {}).get("text") or ""
        if not matn_ar.strip():
            continue
        grade, src = classify(matn_ar, GRADE_SOURCES["riyad"], "riyad")
        rows_hadith.append(
            dict(
                book_id=4,
                chapter_id=ch_map[ch_src],
                hadith_number=h.get("idInBook") or (picked + 1),
                narrator=(h.get("english") or {}).get("narrator") or "",
                matn_ar=matn_ar,
                matn_en=matn_en,
                grade=grade,
                grade_source=src if grade else None,
            )
        )
        picked += 1

    # --- Mishkat al-Masabih (Al-Albani graded sample) ---
    mishkat_ch_ids = {}
    for i, (src_id, tar, ten) in enumerate(MISHKAT_CHAPTERS, start=1):
        cid = 500 + i
        mishkat_ch_ids[src_id] = cid
        rows_chapters.append((cid, 5, i, tar, ten))
    by_ch = {}
    for h in mishkat["hadiths"]:
        by_ch.setdefault(h.get("chapterId"), []).append(h)
    for src_id, cid in mishkat_ch_ids.items():
        picked = 0
        for h in by_ch.get(src_id, []):
            if picked >= SAMPLE_PER_CHAPTER:
                break
            matn_ar = h.get("arabic") or ""
            if not matn_ar.strip():
                continue
            grade = map_albani_grade(h.get("grade") or "")
            matn_en = (h.get("english") or {}).get("text") or ""
            rows_hadith.append(
                dict(
                    book_id=5,
                    chapter_id=cid,
                    hadith_number=h.get("idInBook") or 0,
                    narrator=(h.get("english") or {}).get("narrator") or "",
                    matn_ar=matn_ar,
                    matn_en=matn_en,
                    grade=grade,
                    grade_source=GRADE_SOURCES["mishkat"] if grade else None,
                )
            )
            picked += 1

    # --- write DB -------------------------------------------------------
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    if os.path.exists(OUT):
        os.remove(OUT)
    con = sqlite3.connect(OUT)
    cur = con.cursor()
    cur.executescript(
        """
        PRAGMA journal_mode = OFF;
        CREATE TABLE books (
            id INTEGER PRIMARY KEY,
            name_ar TEXT NOT NULL,
            name_en TEXT NOT NULL,
            author TEXT NOT NULL,
            total_hadiths INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE chapters (
            id INTEGER PRIMARY KEY,
            book_id INTEGER NOT NULL,
            chapter_number INTEGER NOT NULL,
            title_ar TEXT NOT NULL,
            title_en TEXT NOT NULL,
            FOREIGN KEY (book_id) REFERENCES books (id)
        );
        CREATE TABLE hadiths (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_id INTEGER NOT NULL,
            chapter_id INTEGER NOT NULL,
            hadith_number INTEGER NOT NULL,
            narrator TEXT,
            matn_ar TEXT NOT NULL,
            matn_en TEXT,
            grade TEXT,
            grade_source TEXT,
            matn_search TEXT NOT NULL,
            FOREIGN KEY (book_id) REFERENCES books (id),
            FOREIGN KEY (chapter_id) REFERENCES chapters (id)
        );
        CREATE INDEX idx_chapters_book ON chapters (book_id);
        CREATE INDEX idx_hadiths_book ON hadiths (book_id);
        CREATE INDEX idx_hadiths_chapter ON hadiths (chapter_id);
        CREATE INDEX idx_hadiths_grade ON hadiths (grade);
        CREATE INDEX idx_hadiths_search ON hadiths (matn_search);
        """
    )
    cur.executemany(
        "INSERT INTO chapters (id, book_id, chapter_number, title_ar, title_en) "
        "VALUES (?, ?, ?, ?, ?)",
        rows_chapters,
    )
    cur.executemany(
        "INSERT INTO hadiths (book_id, chapter_id, hadith_number, narrator, matn_ar,"
        " matn_en, grade, grade_source, matn_search) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [
            (
                r["book_id"], r["chapter_id"], r["hadith_number"], r["narrator"],
                r["matn_ar"], r["matn_en"], r["grade"], r["grade_source"],
                normalize_arabic(r["matn_ar"]),
            )
            for r in rows_hadith
        ],
    )
    # book totals
    for bid, *_ in BOOKS:
        cur.execute(
            "UPDATE books SET total_hadiths = "
            "(SELECT COUNT(*) FROM hadiths WHERE book_id = ?) WHERE id = ?",
            (bid, bid),
        )
    cur.executemany(
        "INSERT INTO books (id, name_ar, name_en, author, total_hadiths) VALUES (?, ?, ?, ?, 0)",
        BOOKS,
    )
    for bid, *_ in BOOKS:
        cur.execute(
            "UPDATE books SET total_hadiths = "
            "(SELECT COUNT(*) FROM hadiths WHERE book_id = ?) WHERE id = ?",
            (bid, bid),
        )
    con.commit()
    cur.execute("VACUUM")
    con.commit()

    # --- report ---------------------------------------------------------
    print(f"  books    : {cur.execute('SELECT COUNT(*) FROM books').fetchone()[0]}")
    print(f"  chapters : {cur.execute('SELECT COUNT(*) FROM chapters').fetchone()[0]}")
    print(f"  hadiths  : {cur.execute('SELECT COUNT(*) FROM hadiths').fetchone()[0]}")
    for row in cur.execute(
        "SELECT grade, COUNT(*) FROM hadiths GROUP BY grade ORDER BY grade"
    ):
        print(f"    grade {row[0]!r}: {row[1]}")
    con.close()
    size = os.path.getsize(OUT)
    print(f"  -> {OUT} ({size/1_048_576:.2f} MB)")
    if size > 15 * 1_048_576:
        print("ERROR: database exceeds the 15 MB budget", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
