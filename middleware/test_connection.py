"""Minimal REST API test for TigerGraph Savanna."""
import os, requests, json
from dotenv import load_dotenv
load_dotenv()

host = os.getenv("TG_HOST", "").rstrip("/")
secret = os.getenv("TG_SECRET", "")
graph = os.getenv("TG_GRAPH_NAME", "CargoNetwork")

log = []
def p(msg):
    print(msg)
    log.append(str(msg))

p(f"Host: {host}")
p(f"Graph: {graph}")
p(f"Secret: {secret[:8]}...")

# Test 1: Ping via /api/ping
p("\n=== Test 1: /api/ping ===")
for url in [f"{host}/api/ping", f"{host}:9000/api/ping"]:
    try:
        r = requests.get(url, timeout=10)
        p(f"  {url}: {r.status_code} - {r.text[:200]}")
    except Exception as e:
        p(f"  {url}: FAILED - {e}")

# Test 2: Token request
p("\n=== Test 2: Request token ===")
for url in [f"{host}/requesttoken", f"{host}:9000/requesttoken"]:
    try:
        r = requests.post(url, json={"secret": secret, "graph": graph}, timeout=10)
        p(f"  {url}: {r.status_code} - {r.text[:300]}")
    except Exception as e:
        p(f"  {url}: FAILED - {e}")

# Test 3: Bearer auth on echo
p("\n=== Test 3: Echo with bearer ===")
for url in [f"{host}/echo/{graph}", f"{host}:9000/echo/{graph}", f"{host}/echo", f"{host}:9000/echo"]:
    try:
        r = requests.get(url, headers={"Authorization": f"Bearer {secret}"}, timeout=10)
        p(f"  {url}: {r.status_code} - {r.text[:200]}")
    except Exception as e:
        p(f"  {url}: FAILED - {e}")

# Test 4: Check endpoints/version
p("\n=== Test 4: Version/endpoints ===")
for url in [f"{host}/api/version", f"{host}/endpoints/{graph}", f"{host}:14240/api/ping"]:
    try:
        r = requests.get(url, timeout=10)
        p(f"  {url}: {r.status_code} - {r.text[:200]}")
    except Exception as e:
        p(f"  {url}: FAILED - {e}")

# Save log
with open("test_log.py", "w", encoding="utf-8") as f:
    f.write("# REST API Test Results\nRESULT = '''\n")
    f.write("\n".join(log))
    f.write("\n'''\nprint(RESULT)\n")
p("\nLog saved to test_log.py")
