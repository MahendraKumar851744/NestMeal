#!/usr/bin/env python3
"""
NestMeal Test Runner
====================
Run all tests and generate HTML + issues report.

Usage:
    python run_tests.py                   # Run all tests
    python run_tests.py --api             # Run only API tests
    python run_tests.py --ui              # Run only UI tests
    python run_tests.py --smoke           # Run only smoke tests
    python run_tests.py --critical        # Run only critical issue tests
    python run_tests.py -k "test_login"   # Run tests matching pattern
"""

import subprocess
import sys
import os
from datetime import datetime

TESTING_DIR = os.path.dirname(os.path.abspath(__file__))
REPORTS_DIR = os.path.join(TESTING_DIR, "reports")
os.makedirs(REPORTS_DIR, exist_ok=True)

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")


def run_tests(extra_args=None):
    """Run pytest with HTML report generation."""
    report_file = os.path.join(REPORTS_DIR, f"test_report_{timestamp}.html")

    cmd = [
        sys.executable, "-m", "pytest",
        "--html", report_file,
        "--self-contained-html",
        "-v",
        "--tb=short",
    ]

    if extra_args:
        cmd.extend(extra_args)

    print(f"\n{'='*60}")
    print(f"  NestMeal Test Suite Runner")
    print(f"  Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"  Report:  {report_file}")
    print(f"{'='*60}\n")

    result = subprocess.run(cmd, cwd=TESTING_DIR)

    print(f"\n{'='*60}")
    print(f"  Test run complete.")
    print(f"  HTML Report: {report_file}")
    issues_file = os.path.join(REPORTS_DIR, "issues_found.md")
    if os.path.exists(issues_file):
        print(f"  Issues Report: {issues_file}")
    print(f"{'='*60}\n")

    return result.returncode


if __name__ == "__main__":
    args = sys.argv[1:]
    extra = []

    if "--api" in args:
        extra.append("api_tests/")
        args.remove("--api")
    elif "--ui" in args:
        extra.append("ui_tests/")
        args.remove("--ui")
    elif "--smoke" in args:
        extra.extend(["-m", "smoke"])
        args.remove("--smoke")
    elif "--critical" in args:
        extra.extend(["-m", "critical"])
        args.remove("--critical")

    extra.extend(args)
    exit_code = run_tests(extra)
    sys.exit(exit_code)
