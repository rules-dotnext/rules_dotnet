#!/usr/bin/env python3
"""Capture targeted BuildBuddy screenshots for proof evidence.

Uses authenticated playwright sessions via bb_cookies.json.
Each screenshot captures a specific tab that proves a specific
property (correctness, hermeticity, determinism, remote cache).

Only captures the minimum set of screenshots needed — each one
must prove something distinct. No redundant views.

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

    # Post-fix invocations: 165/165 tests pass, zero failures
    COLD = "e297c5fb-d14e-4699-ac8d-e09adf24e023"
    WARM = "2470f621-6a46-4f75-b430-a827892f2896"
    REMOTE = "b1a42431-938d-4370-ba74-48fd4c6923ba"

    # Each entry: (invocation_id, tab, filename, what_it_proves)
    shots = [
        (COLD,   "Targets", "01_165_tests_passed_zero_failures.png",
         "All 165 tests green — proves correctness"),
        (COLD,   "Cache",   "02_cold_build_cache_baseline_523hits_4misses.png",
         "AC 523/4 — establishes remote cache baseline"),
        (WARM,   "ALL",     "03_warm_rebuild_954ms_1action_hermeticity.png",
         "954ms, 1 action — proves hermeticity"),
        (WARM,   "Cache",   "04_warm_rebuild_zero_cache_zero_transfer.png",
         "0/0 AC, 0B transfer — confirms local cache sufficiency"),
        (REMOTE, "Cache",   "05_remote_cache_527hits_zero_misses.png",
         "527/0 AC, 1.836GB — proves remote cache portability"),
        (REMOTE, "ALL",     "06_remote_cache_165tests_pass_after_clean.png",
         "165 pass after clean — proves reproducibility from remote"),
    ]

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
    print(f"\nDone — {count} evidence screenshots in {SCREENSHOT_DIR}/")


if __name__ == "__main__":
    main()
