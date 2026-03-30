"""
NestMeal Test Suite - Shared Fixtures & Configuration
=====================================================
Provides reusable fixtures for API and UI tests.
"""

import pytest
import requests
import time
import json
import os
from datetime import datetime

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

BASE_URL = os.getenv("NESTMEAL_API_URL", "http://127.0.0.1:8000/api")
FLUTTER_WEB_URL = os.getenv("NESTMEAL_WEB_URL", "http://localhost:8080")
HEADLESS = os.getenv("HEADLESS", "true").lower() == "true"

# Test accounts (created by test setup script)
TEST_CUSTOMERS = [
    {"email": "testcustomer@nestmeal.com", "password": "TestPass@123"},
    {"email": "testcustomer2@nestmeal.com", "password": "TestPass@123"},
]

TEST_COOKS = [
    {"email": "testcook@nestmeal.com", "password": "TestPass@123"},
]

# Fresh user for registration tests
TEST_NEW_USER = {
    "email": f"testuser_{int(time.time())}@test.com",
    "password": "TestPass@123",
    "full_name": "Test User",
    "phone": "+61400000000",
    "role": "customer",
}

MOCK_OTP = "1234"


# ---------------------------------------------------------------------------
# Report directory
# ---------------------------------------------------------------------------

REPORTS_DIR = os.path.join(os.path.dirname(__file__), "reports")
os.makedirs(REPORTS_DIR, exist_ok=True)


# ---------------------------------------------------------------------------
# Issue Tracker
# ---------------------------------------------------------------------------

class IssueTracker:
    """Collects issues found during testing and writes them to a report."""

    def __init__(self):
        self.issues = []
        self._counter = 0

    def add(self, title, description, severity, category, endpoint=None,
            screen=None, steps_to_reproduce=None, expected=None, actual=None,
            related_tracker_issue=None):
        self._counter += 1
        issue = {
            "id": f"T-{self._counter:03d}",
            "title": title,
            "description": description,
            "severity": severity,  # CRITICAL, HIGH, MEDIUM, LOW
            "category": category,  # API, UI, LOGIC, SECURITY, PERFORMANCE
            "endpoint": endpoint,
            "screen": screen,
            "steps_to_reproduce": steps_to_reproduce or [],
            "expected": expected,
            "actual": actual,
            "related_tracker_issue": related_tracker_issue,
            "found_at": datetime.now().isoformat(),
        }
        self.issues.append(issue)
        return issue

    def generate_report(self, filepath=None):
        if filepath is None:
            filepath = os.path.join(REPORTS_DIR, "issues_found.md")

        severity_order = {"CRITICAL": 0, "HIGH": 1, "MEDIUM": 2, "LOW": 3}
        sorted_issues = sorted(
            self.issues,
            key=lambda x: severity_order.get(x["severity"], 99),
        )

        lines = [
            "# NestMeal Test Issues Report",
            f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            f"**Total Issues Found:** {len(self.issues)}",
            "",
            "| Severity | Count |",
            "|----------|-------|",
        ]
        for sev in ["CRITICAL", "HIGH", "MEDIUM", "LOW"]:
            count = sum(1 for i in sorted_issues if i["severity"] == sev)
            lines.append(f"| {sev} | {count} |")
        lines.append("")
        lines.append("---")
        lines.append("")

        for issue in sorted_issues:
            lines.append(f"## {issue['id']}: {issue['title']}")
            lines.append(f"**Severity:** {issue['severity']} | "
                         f"**Category:** {issue['category']}")
            if issue.get("endpoint"):
                lines.append(f"**Endpoint:** `{issue['endpoint']}`")
            if issue.get("screen"):
                lines.append(f"**Screen:** {issue['screen']}")
            if issue.get("related_tracker_issue"):
                lines.append(f"**Related Tracker Issue:** #{issue['related_tracker_issue']}")
            lines.append("")
            lines.append(issue["description"])
            lines.append("")
            if issue.get("steps_to_reproduce"):
                lines.append("**Steps to Reproduce:**")
                for i, step in enumerate(issue["steps_to_reproduce"], 1):
                    lines.append(f"{i}. {step}")
                lines.append("")
            if issue.get("expected"):
                lines.append(f"**Expected:** {issue['expected']}")
            if issue.get("actual"):
                lines.append(f"**Actual:** {issue['actual']}")
            lines.append("")
            lines.append("---")
            lines.append("")

        with open(filepath, "w", encoding="utf-8") as f:
            f.write("\n".join(lines))
        return filepath


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture(scope="session")
def issue_tracker():
    """Session-scoped issue tracker that generates a report at the end."""
    tracker = IssueTracker()
    yield tracker
    tracker.generate_report()


@pytest.fixture(scope="session")
def api_base_url():
    return BASE_URL


@pytest.fixture(scope="session")
def api_session():
    """A requests.Session with common settings."""
    s = requests.Session()
    s.headers.update({"Content-Type": "application/json"})
    s.timeout = 15
    return s


def _login(session, email, password, base_url):
    """Helper: login and return tokens + user data."""
    resp = session.post(
        f"{base_url}/accounts/login/",
        json={"email": email, "password": password},
    )
    return resp


@pytest.fixture(scope="session")
def customer_auth(api_session, api_base_url):
    """Login as first test customer and return (tokens, user)."""
    for cred in TEST_CUSTOMERS:
        resp = _login(api_session, cred["email"], cred["password"], api_base_url)
        if resp.status_code == 200:
            data = resp.json()
            return {
                "access": data["tokens"]["access"],
                "refresh": data["tokens"]["refresh"],
                "user": data["user"],
                "headers": {"Authorization": f"Bearer {data['tokens']['access']}"},
            }
    pytest.skip("No test customer could be authenticated - check seed data")


@pytest.fixture(scope="session")
def cook_auth(api_session, api_base_url):
    """Login as first test cook and return (tokens, user)."""
    for cred in TEST_COOKS:
        resp = _login(api_session, cred["email"], cred["password"], api_base_url)
        if resp.status_code == 200:
            data = resp.json()
            return {
                "access": data["tokens"]["access"],
                "refresh": data["tokens"]["refresh"],
                "user": data["user"],
                "headers": {"Authorization": f"Bearer {data['tokens']['access']}"},
            }
    pytest.skip("No test cook could be authenticated - check seed data")


@pytest.fixture(scope="session")
def customer_headers(customer_auth):
    return customer_auth["headers"]


@pytest.fixture(scope="session")
def cook_headers(cook_auth):
    return cook_auth["headers"]


# ---------------------------------------------------------------------------
# Selenium fixtures
# ---------------------------------------------------------------------------

@pytest.fixture(scope="session")
def chrome_driver():
    """Create a Chrome WebDriver for UI testing."""
    from selenium import webdriver
    from selenium.webdriver.chrome.service import Service
    from selenium.webdriver.chrome.options import Options
    from webdriver_manager.chrome import ChromeDriverManager

    options = Options()
    if HEADLESS:
        options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--window-size=1920,1080")
    options.add_argument("--disable-gpu")

    service = Service(ChromeDriverManager().install())
    driver = webdriver.Chrome(service=service, options=options)
    driver.implicitly_wait(10)
    yield driver
    driver.quit()


@pytest.fixture
def web_url():
    return FLUTTER_WEB_URL
