"""
Test Suite: Flutter Web UI Smoke Tests (Selenium)
=================================================
Tests basic page loading, navigation, login/registration flows.
NOTE: Flutter Web (HTML renderer) uses semantic elements that Selenium can work with.
      CanvasKit renderer renders to canvas, making Selenium testing very limited.
      These tests target the HTML renderer: flutter run -d chrome --web-renderer html
"""

import pytest
import time
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException

from conftest import FLUTTER_WEB_URL, TEST_CUSTOMERS, TEST_COOKS


WAIT_TIMEOUT = 15


@pytest.mark.ui
@pytest.mark.smoke
class TestAppLoading:
    """Test that the Flutter web app loads successfully."""

    def test_app_loads(self, chrome_driver, issue_tracker):
        """App should load without crashing."""
        try:
            chrome_driver.get(FLUTTER_WEB_URL)
            time.sleep(5)  # Flutter needs time to bootstrap

            # Check page title
            title = chrome_driver.title
            if "Error" in title or "404" in title:
                issue_tracker.add(
                    title="App fails to load",
                    description=f"Page title: {title}",
                    severity="CRITICAL",
                    category="UI",
                    screen="App Loading",
                )

            # Check for Flutter engine errors in console
            logs = chrome_driver.get_log("browser")
            severe_errors = [l for l in logs if l.get("level") == "SEVERE"]
            for error in severe_errors:
                msg = error.get("message", "")
                if "canvaskit" in msg.lower() or "failed to fetch" in msg.lower():
                    issue_tracker.add(
                        title="Flutter engine error on load",
                        description=f"Browser console error: {msg[:300]}",
                        severity="CRITICAL",
                        category="UI",
                        screen="App Loading",
                    )

        except Exception as e:
            issue_tracker.add(
                title="App completely fails to load",
                description=f"Exception: {str(e)[:300]}",
                severity="CRITICAL",
                category="UI",
                screen="App Loading",
            )
            pytest.fail(f"App failed to load: {e}")

    def test_no_console_errors(self, chrome_driver, issue_tracker):
        """App should load without severe JS errors."""
        chrome_driver.get(FLUTTER_WEB_URL)
        time.sleep(5)

        try:
            logs = chrome_driver.get_log("browser")
            severe = [l for l in logs if l.get("level") == "SEVERE"]
            js_errors = [l for l in severe if "TypeError" in l.get("message", "")
                         or "ReferenceError" in l.get("message", "")]
            for error in js_errors:
                issue_tracker.add(
                    title="JavaScript error on page load",
                    description=error.get("message", "")[:300],
                    severity="HIGH",
                    category="UI",
                    screen="App Loading",
                )
        except Exception:
            pass  # Some drivers don't support get_log

    def test_responsive_viewport(self, chrome_driver, issue_tracker):
        """App should render at mobile viewport size."""
        chrome_driver.set_window_size(375, 812)  # iPhone X size
        chrome_driver.get(FLUTTER_WEB_URL)
        time.sleep(5)

        # Check viewport meta tag exists
        meta = chrome_driver.find_elements(By.CSS_SELECTOR, "meta[name='viewport']")
        # Flutter doesn't set viewport meta by default but should still render

        # Check for horizontal overflow
        body_width = chrome_driver.execute_script("return document.body.scrollWidth")
        viewport_width = chrome_driver.execute_script("return window.innerWidth")
        if body_width > viewport_width + 50:
            issue_tracker.add(
                title="Horizontal overflow on mobile viewport",
                description=f"Body width {body_width}px exceeds viewport {viewport_width}px",
                severity="MEDIUM",
                category="UI",
                screen="App (mobile viewport)",
            )

        # Reset window size
        chrome_driver.set_window_size(1920, 1080)


@pytest.mark.ui
class TestLoginScreen:
    """Test login screen UI elements and functionality."""

    def test_login_screen_elements(self, chrome_driver, issue_tracker):
        """Login screen should have email, password, and submit elements."""
        chrome_driver.get(FLUTTER_WEB_URL)
        time.sleep(8)  # Wait for Flutter to render

        page_source = chrome_driver.page_source

        # Check for login-related text
        login_keywords = ["login", "sign in", "email", "password"]
        found_any = False
        for keyword in login_keywords:
            if keyword.lower() in page_source.lower():
                found_any = True
                break

        if not found_any:
            # Might be already logged in or on a different screen
            issue_tracker.add(
                title="Login screen not displayed on app launch",
                description="No login-related text found on initial page load. App may auto-login or show splash.",
                severity="MEDIUM",
                category="UI",
                screen="LoginScreen",
                expected="Login screen with email/password fields",
                actual="Different screen displayed",
            )

    def test_page_has_input_fields(self, chrome_driver, issue_tracker):
        """Page should have input fields for login."""
        chrome_driver.get(FLUTTER_WEB_URL)
        time.sleep(8)

        # Flutter web uses <input> elements in HTML mode
        inputs = chrome_driver.find_elements(By.TAG_NAME, "input")
        if len(inputs) == 0:
            # In CanvasKit mode, there are no HTML inputs
            issue_tracker.add(
                title="No HTML input elements found (CanvasKit mode?)",
                description="App may be using CanvasKit renderer which renders to canvas. "
                            "Selenium cannot interact with canvas-rendered elements. "
                            "Use --web-renderer html for testability.",
                severity="MEDIUM",
                category="UI",
                screen="LoginScreen",
            )


@pytest.mark.ui
class TestScreenNavigation:
    """Test basic screen navigation via URL routes."""

    def test_direct_url_navigation(self, chrome_driver, issue_tracker):
        """Test that direct URL navigation doesn't crash the app."""
        routes = [
            "/",
            "/#/login",
            "/#/register",
        ]
        for route in routes:
            try:
                chrome_driver.get(f"{FLUTTER_WEB_URL}{route}")
                time.sleep(3)
                # Check for blank white screen
                body_text = chrome_driver.execute_script(
                    "return document.body.innerText || ''"
                )
                if "error" in body_text.lower() and "exception" in body_text.lower():
                    issue_tracker.add(
                        title=f"Error displayed at route {route}",
                        description=f"Page shows error text: {body_text[:200]}",
                        severity="HIGH",
                        category="UI",
                        screen=f"Route: {route}",
                    )
            except Exception as e:
                issue_tracker.add(
                    title=f"Navigation to {route} crashes",
                    description=str(e)[:300],
                    severity="HIGH",
                    category="UI",
                    screen=f"Route: {route}",
                )


@pytest.mark.ui
class TestPerformance:
    """Test basic performance metrics."""

    def test_page_load_time(self, chrome_driver, issue_tracker):
        """App should load within reasonable time."""
        start = time.time()
        chrome_driver.get(FLUTTER_WEB_URL)

        # Wait for Flutter to be ready (check for flt-glass-pane or similar)
        try:
            WebDriverWait(chrome_driver, 30).until(
                lambda d: d.execute_script(
                    "return document.querySelector('flutter-view') !== null "
                    "|| document.querySelector('flt-glass-pane') !== null "
                    "|| document.querySelector('canvas') !== null"
                )
            )
        except TimeoutException:
            pass

        load_time = time.time() - start

        if load_time > 20:
            issue_tracker.add(
                title=f"Slow initial page load: {load_time:.1f}s",
                description=f"App took {load_time:.1f} seconds to load (target: <10s)",
                severity="MEDIUM",
                category="PERFORMANCE",
                screen="App Loading",
                expected="Load time < 10 seconds",
                actual=f"{load_time:.1f} seconds",
            )

    def test_page_memory_usage(self, chrome_driver, issue_tracker):
        """Check for excessive memory usage."""
        chrome_driver.get(FLUTTER_WEB_URL)
        time.sleep(10)

        try:
            memory = chrome_driver.execute_script(
                "return window.performance && window.performance.memory "
                "? window.performance.memory.usedJSHeapSize : null"
            )
            if memory and memory > 200 * 1024 * 1024:  # 200MB
                issue_tracker.add(
                    title=f"High memory usage: {memory / (1024*1024):.0f}MB",
                    description=f"JS heap size is {memory / (1024*1024):.0f}MB (threshold: 200MB)",
                    severity="LOW",
                    category="PERFORMANCE",
                    screen="App",
                )
        except Exception:
            pass  # Not all browsers support performance.memory


@pytest.mark.ui
class TestAccessibility:
    """Basic accessibility checks."""

    def test_page_has_title(self, chrome_driver, issue_tracker):
        """Page should have a meaningful title."""
        chrome_driver.get(FLUTTER_WEB_URL)
        time.sleep(5)
        title = chrome_driver.title
        if not title or title == "nestmeal_app":
            issue_tracker.add(
                title="App has generic/missing page title",
                description=f"Page title is '{title}' - should be 'NestMeal' or similar brand name",
                severity="LOW",
                category="UI",
                screen="App",
                expected="Branded page title like 'NestMeal'",
                actual=f"Title: '{title}'",
            )

    def test_page_has_lang_attribute(self, chrome_driver, issue_tracker):
        """HTML should have lang attribute for accessibility."""
        chrome_driver.get(FLUTTER_WEB_URL)
        time.sleep(3)
        lang = chrome_driver.execute_script(
            "return document.documentElement.getAttribute('lang')"
        )
        if not lang:
            issue_tracker.add(
                title="Missing lang attribute on HTML element",
                description="<html> element missing lang attribute for screen readers",
                severity="LOW",
                category="UI",
                screen="App",
            )

    def test_page_has_favicon(self, chrome_driver, issue_tracker):
        """Page should have a favicon."""
        chrome_driver.get(FLUTTER_WEB_URL)
        time.sleep(3)
        favicons = chrome_driver.find_elements(
            By.CSS_SELECTOR, "link[rel='icon'], link[rel='shortcut icon']"
        )
        if not favicons:
            issue_tracker.add(
                title="Missing favicon",
                description="No favicon link element found",
                severity="LOW",
                category="UI",
                screen="App",
            )
