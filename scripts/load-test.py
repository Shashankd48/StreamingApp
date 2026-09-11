#!/usr/bin/env python3
"""
StreamingApp - Kubernetes Autoscaling (HPA) & Ingress Load Test Suite
Executes concurrent synthetic traffic against the AWS Application Load Balancer
to evaluate latency, throughput, and trigger Horizontal Pod Autoscaling.
"""

import sys
import time
import urllib.request
import urllib.error
import concurrent.futures
from statistics import mean, quantiles

DEFAULT_BASE_URL = "http://a58ecf898ca284bbf9056d00d934692a-1428735725.ap-south-1.elb.amazonaws.com"

ENDPOINTS = {
    "frontend": "/",
    "streaming": "/api/streaming/streaming/videos",
    "auth_health": "/api/auth/health",
    "admin_health": "/api/admin/health",
    "chat_health": "/api/chat/health",
}

def make_request(url, timeout=5):
    start = time.perf_counter()
    try:
        req = urllib.request.Request(
            url,
            headers={
                "User-Agent": "StreamingApp-LoadTest/1.0",
                "Accept": "*/*"
            }
        )
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            code = resp.getcode()
            elapsed = (time.perf_counter() - start) * 1000  # ms
            return (code, elapsed, None)
    except urllib.error.HTTPError as e:
        elapsed = (time.perf_counter() - start) * 1000
        return (e.code, elapsed, str(e.reason))
    except Exception as e:
        elapsed = (time.perf_counter() - start) * 1000
        return (0, elapsed, str(e))

def run_load_test(target_url, concurrency=20, total_requests=1000):
    print(f"\n========================================================")
    print(f" Target:      {target_url}")
    print(f" Concurrency: {concurrency} workers")
    print(f" Total Reqs:  {total_requests}")
    print(f"========================================================")

    latencies = []
    status_codes = {}
    errors = 0

    wall_start = time.perf_counter()

    with concurrent.futures.ThreadPoolExecutor(max_workers=concurrency) as executor:
        futures = [executor.submit(make_request, target_url) for _ in range(total_requests)]
        for f in concurrent.futures.as_completed(futures):
            code, lat, err = f.result()
            latencies.append(lat)
            status_codes[code] = status_codes.get(code, 0) + 1
            if code < 200 or code >= 400:
                errors += 1

    wall_time = time.perf_counter() - wall_start
    rps = total_requests / wall_time if wall_time > 0 else 0

    latencies.sort()
    p50 = latencies[int(len(latencies) * 0.50)]
    p90 = latencies[int(len(latencies) * 0.90)]
    p95 = latencies[int(len(latencies) * 0.95)]
    p99 = latencies[int(len(latencies) * 0.99)]
    avg_lat = mean(latencies)
    min_lat = min(latencies)
    max_lat = max(latencies)

    print("\n--- Load Test Results ---")
    print(f" Total Duration:   {wall_time:.2f} s")
    print(f" Throughput (RPS): {rps:.2f} req/sec")
    print(f" Status Codes:     {dict(sorted(status_codes.items()))}")
    print(f" Errors:           {errors} ({errors/total_requests*100:.1f}%)")
    print(f" Latency (min):    {min_lat:.2f} ms")
    print(f" Latency (avg):    {avg_lat:.2f} ms")
    print(f" Latency (p50):    {p50:.2f} ms")
    print(f" Latency (p90):    {p90:.2f} ms")
    print(f" Latency (p95):    {p95:.2f} ms")
    print(f" Latency (p99):    {p99:.2f} ms")
    print(f" Latency (max):    {max_lat:.2f} ms")
    print("========================================================\n")

if __name__ == "__main__":
    base_url = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_BASE_URL
    target = sys.argv[2] if len(sys.argv) > 2 else "frontend"
    concurrency = int(sys.argv[3]) if len(sys.argv) > 3 else 25
    requests = int(sys.argv[4]) if len(sys.argv) > 4 else 1000

    url = base_url + ENDPOINTS.get(target, target)
    run_load_test(url, concurrency=concurrency, total_requests=requests)
