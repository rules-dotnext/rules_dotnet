#!/usr/bin/env python3
"""Capture targeted BuildBuddy screenshots for tri-platform proof evidence.

Uses authenticated playwright sessions via bb_cookies.json.
Each screenshot captures a specific tab proving a specific property.

Usage:
    python3.12 capture_bb_screenshots.py
"""

import json
import time
from pathlib import Path

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parent.parent.parent
COOKIES_FILE = ROOT / "bb_cookies.json"
SCREENSHOT_DIR = ROOT / "validation" / "proof-sequence" / "screenshots"

# Tri-platform BES invocations from validation.yml run 23015365834
INVOCATIONS = {
    "linux": {
        "cold":    "6e8ecae6-0502-4196-a8f8-035dc199348b",
        "warm":    "3e2a97ed-09af-4dc0-a928-34c5f47b2d5f",
        "incr":    "24555b90-4d44-4082-946c-45e8df00b0ad",
        "remote":  "73bb5361-51f3-4a43-8227-a5b10df74c7d",
    },
    "macos": {
        "cold":    "449d8b96-9458-4119-8c62-09bfaf1d20d1",
        "warm":    "be5ecc5a-0bae-4883-8403-2f52cae10b1b",
        "incr":    "4848df2b-9aa2-47c3-8c29-d5e334a37c07",
        "remote":  "9c198c28-ed70-4895-9417-54cc69c119a9",
    },
    "windows": {
        "cold":    "7eed1e85-74f1-43a5-99a2-b58389c335d1",
        "warm":    "4666aac9-7b93-467b-963b-78cd4b2cd8c1",
        "incr":    "b714757d-4bd8-4b63-9cfb-5703c90c6253",
        "remote":  "8677e2fe-9f75-4c79-8884-242d587ab804",
    },
}


def load_cookies():
    return json.loads(COOKIES_FILE.read_text())


def click_tab(page, tab_name):
    """Click a BuildBuddy invocation tab by exact text."""
    tab = page.locator(f"a.tab >> text='{tab_name}'").first
    if tab.count() > 0 and tab.is_visible():
        tab.click()
        time.sleep(3)
        return True
    return False


def capture(context, inv_id, tab, filename):
    """Capture a single screenshot of a specific invocation tab."""
    page = context.new_page()
    url = f"https://app.buildbuddy.io/invocation/{inv_id}"
    page.goto(url, wait_until="networkidle", timeout=30000)
    time.sleep(4)

    if tab != "ALL":
        if not click_tab(page, tab):
            print(f"  WARN: {tab} tab not found for {inv_id[:8]}")
            page.close()
            return False

    path = SCREENSHOT_DIR / filename
    page.screenshot(path=str(path), full_page=False)
    print(f"  {filename}")
    page.close()
    return True


def main():
    SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)

    # Clean old screenshots
    for f in SCREENSHOT_DIR.glob("*.png"):
        f.unlink()

    cookies = load_cookies()

    # Key screenshots per platform — one per proof property.
    # Cold build (Targets tab): proves correctness — shows test count + pass/fail
    # Warm rebuild (overview): proves hermeticity — shows 0 executed
    # Remote cache (Cache tab): proves cache compatibility — shows hit/miss ratio
    #
    # Incremental is proven by the BES link (0 executed on warm, N on incr);
    # a screenshot adds little over the table data.
    shots = []
    for platform in ["linux", "macos", "windows"]:
        inv = INVOCATIONS[platform]
        shots.extend([
            (inv["cold"],   "Targets", f"{platform}_cold_targets.png",
             f"{platform}: cold build — all tests pass"),
            (inv["warm"],   "ALL",     f"{platform}_warm_overview.png",
             f"{platform}: warm rebuild — 0 executed, hermeticity"),
            (inv["remote"], "Cache",   f"{platform}_remote_cache.png",
             f"{platform}: remote cache — hit/miss ratio"),
        ])

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={"width": 1400, "height": 900},
            device_scale_factor=2,
        )
        context.add_cookies(cookies)

        for inv_id, tab, filename, desc in shots:
            print(f"\n{desc}")
            capture(context, inv_id, tab, filename)

        browser.close()

    count = len(list(SCREENSHOT_DIR.glob("*.png")))
    print(f"\nDone — {count} screenshots in {SCREENSHOT_DIR}/")


if __name__ == "__main__":
    main()
