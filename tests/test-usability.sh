#!/bin/bash
# Basic usability test script for remote desktop deployment
# Run this to verify the environment is usable

SERVER="root@204.168.182.32"
PASS=0
FAIL=0

echo "=========================================="
echo "  Remote Desktop Usability Tests"
echo "=========================================="
echo ""

# Test 1: Check xrdp is listening on port 3389
echo "[TEST 1] Checking xrdp is listening on port 3389..."
if ssh $SERVER "netstat -tlnp | grep -q ':3389.*LISTEN.*xrdp'" 2>/dev/null; then
    echo "  ✓ PASS: xrdp is listening on port 3389"
    ((PASS++))
else
    echo "  ✗ FAIL: xrdp is NOT listening on port 3389"
    ((FAIL++))
fi

# Test 2: Check xrdp process is running
echo "[TEST 2] Checking xrdp daemon is running..."
if ssh $SERVER "ps aux | grep -v grep | grep -q '/usr/sbin/xrdp'" 2>/dev/null; then
    echo "  ✓ PASS: xrdp daemon is running"
    ((PASS++))
else
    echo "  ✗ FAIL: xrdp daemon is NOT running"
    ((FAIL++))
fi

# Test 3: Check xrdp-sesman is running
echo "[TEST 3] Checking xrdp-sesman is running..."
if ssh $SERVER "ps aux | grep -v grep | grep -q 'xrdp-sesman'" 2>/dev/null; then
    echo "  ✓ PASS: xrdp-sesman is running"
    ((PASS++))
else
    echo "  ✗ FAIL: xrdp-sesman is NOT running"
    ((FAIL++))
fi

# Test 4: Check GNOME session binaries exist
echo "[TEST 4] Checking GNOME session binaries..."
if ssh $SERVER "command -v gnome-session && command -v gnome-shell" >/dev/null 2>&1; then
    echo "  ✓ PASS: GNOME session binaries exist"
    ((PASS++))
else
    echo "  ✗ FAIL: GNOME session binaries NOT found"
    ((FAIL++))
fi

# Test 5: Check dbus-launch is available
echo "[TEST 5] Checking dbus-launch is available..."
if ssh $SERVER "command -v dbus-launch" >/dev/null 2>&1; then
    echo "  ✓ PASS: dbus-launch is available"
    ((PASS++))
else
    echo "  ✗ FAIL: dbus-launch NOT found"
    ((FAIL++))
fi

# Test 6: Check desktop user exists
echo "[TEST 6] Checking desktop user exists..."
if ssh $SERVER "id desktopuser" >/dev/null 2>&1; then
    echo "  ✓ PASS: desktopuser exists"
    ((PASS++))
else
    echo "  ✗ FAIL: desktopuser NOT found"
    ((FAIL++))
fi

# Test 7: Check startwm.sh exists and is executable
echo "[TEST 7] Checking startwm.sh is configured..."
if ssh $SERVER "[ -x /etc/xrdp/startwm.sh ]" 2>/dev/null; then
    echo "  ✓ PASS: startwm.sh is executable"
    ((PASS++))
else
    echo "  ✗ FAIL: startwm.sh is NOT executable"
    ((FAIL++))
fi

# Test 8: Check startwm.sh has X11 backend forced
echo "[TEST 8] Checking startwm.sh has X11 backend forced..."
if ssh $SERVER "grep -q 'GDK_BACKEND=x11' /etc/xrdp/startwm.sh" 2>/dev/null; then
    echo "  ✓ PASS: GDK_BACKEND=x11 is set"
    ((PASS++))
else
    echo "  ✗ FAIL: GDK_BACKEND=x11 NOT configured"
    ((FAIL++))
fi

# Test 9: Check desktop shortcuts exist
echo "[TEST 9] Checking desktop shortcuts..."
SHORTCUTS=$(ssh $SERVER "ls /home/desktopuser/Desktop/*.desktop 2>/dev/null | wc -l")
if [ "$SHORTCUTS" -ge 3 ]; then
    echo "  ✓ PASS: Desktop shortcuts exist ($SHORTCUTS found)"
    ((PASS++))
else
    echo "  ✗ FAIL: Missing desktop shortcuts (found $SHORTCUTS, expected 3+)"
    ((FAIL++))
fi

# Test 10: Check VS Code is installed
echo "[TEST 10] Checking VS Code is installed..."
if ssh $SERVER "command -v code" >/dev/null 2>&1; then
    echo "  ✓ PASS: VS Code is installed"
    ((PASS++))
else
    echo "  ✗ FAIL: VS Code NOT found"
    ((FAIL++))
fi

# Test 11: Check Chrome/Chromium is installed
echo "[TEST 11] Checking Chromium browser is installed..."
if ssh $SERVER "command -v google-chrome || command -v chromium" >/dev/null 2>&1; then
    echo "  ✓ PASS: Browser is installed"
    ((PASS++))
else
    echo "  ✗ FAIL: Browser NOT found"
    ((FAIL++))
fi

# Test 12: Check Claude Code is installed
echo "[TEST 12] Checking Claude Code is installed..."
if ssh $SERVER "command -v claude" >/dev/null 2>&1; then
    echo "  ✓ PASS: Claude Code is installed"
    ((PASS++))
else
    echo "  ✗ FAIL: Claude Code NOT found"
    ((FAIL++))
fi

echo ""
echo "=========================================="
echo "  Test Results: $PASS passed, $FAIL failed"
echo "=========================================="

if [ $FAIL -eq 0 ]; then
    echo "  ✓ All tests passed! Environment is usable."
    exit 0
else
    echo "  ✗ Some tests failed. Review failures above."
    exit 1
fi
