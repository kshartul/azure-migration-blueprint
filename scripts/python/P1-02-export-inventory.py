#!/usr/bin/env python3
"""
Azure Migration Inventory Export & Wave Assignment
---------------------------------------------------
Calls the Azure Migrate REST API to export all discovered servers,
scores each by complexity (CPU, memory, disk count), and assigns
Wave 1 / 2 / 3 for migration wave planning.

Usage:
    export AZURE_SUBSCRIPTION_ID="your-subscription-id"
    export MIGRATE_RG="rg-migrate-prod"
    export MIGRATE_PROJECT="migration-project-01"
    python P1-02-export-inventory.py

Output:
    migration_inventory.csv
"""
import os
import csv
import sys
import json
import requests
from datetime import datetime
from azure.identity import DefaultAzureCredential


SUBSCRIPTION_ID = os.environ["AZURE_SUBSCRIPTION_ID"]
RESOURCE_GROUP  = os.environ["MIGRATE_RG"]
PROJECT_NAME    = os.environ["MIGRATE_PROJECT"]
OUTPUT_FILE     = "migration_inventory.csv"

credential = DefaultAzureCredential()


def get_token() -> str:
    return credential.get_token("https://management.azure.com/.default").token


def get_headers() -> dict:
    return {
        "Authorization": f"Bearer {get_token()}",
        "Content-Type":  "application/json",
    }


def fetch_discovered_servers() -> list:
    base = "https://management.azure.com"
    path = (
        f"/subscriptions/{SUBSCRIPTION_ID}/resourceGroups/{RESOURCE_GROUP}"
        f"/providers/Microsoft.Migrate/MigrateProjects/{PROJECT_NAME}"
        f"/solutions/Servers-Discovery-ServerDiscovery/databases"
        f"?api-version=2023-06-06"
    )
    resp = requests.get(base + path, headers=get_headers())
    resp.raise_for_status()
    return resp.json().get("value", [])


def score_workload(server: dict) -> dict:
    """Score each server by complexity. Higher = migrate later."""
    props = server.get("properties", {})
    cores = props.get("numberOfProcessorCore", 0)
    mem   = props.get("allocatedMemoryInMB", 0) / 1024  # GB
    disks = len(props.get("disks", {}))
    apps  = len(props.get("installedApplications", []))

    # Weighted complexity score
    score = (cores * 2) + (mem * 0.5) + (disks * 3) + (apps * 0.5)

    if score > 40:
        tier = "T1-Critical"
    elif score > 20:
        tier = "T2-Standard"
    else:
        tier = "T3-Simple"

    return {
        "ServerName":       props.get("displayName", "Unknown"),
        "FQDN":             props.get("fqdn", ""),
        "OperatingSystem":  props.get("guestOSName", "Unknown"),
        "Cores":            cores,
        "MemoryGB":         round(mem, 1),
        "DiskCount":        disks,
        "AppCount":         apps,
        "PowerState":       props.get("powerStatus", "Unknown"),
        "IPAddresses":      ", ".join(
            [ip.get("ipAddress", "") for ip in props.get("networkAdapters", {}).values()
             for ip in ip.get("ipAddressList", [])]
        ),
        "ComplexityScore":  round(score, 1),
        "SuggestedTier":    tier,
        "Wave":             "",  # assigned below
    }


def assign_waves(scored: list) -> list:
    """Assign Wave 1/2/3 based on complexity score percentile."""
    total = len(scored)
    if total == 0:
        return scored
    wave1_cutoff = int(total * 0.40)
    wave2_cutoff = int(total * 0.80)
    for i, s in enumerate(scored):
        if i < wave1_cutoff:
            s["Wave"] = "Wave-1"
        elif i < wave2_cutoff:
            s["Wave"] = "Wave-2"
        else:
            s["Wave"] = "Wave-3"
    return scored


def main():
    print(f"Fetching discovered servers from project: {PROJECT_NAME}")
    servers = fetch_discovered_servers()
    print(f"  Discovered: {len(servers)} servers")

    if not servers:
        print("No servers discovered. Ensure discovery has run for at least 30 days.")
        sys.exit(1)

    scored = sorted([score_workload(s) for s in servers],
                    key=lambda x: x["ComplexityScore"])
    scored = assign_waves(scored)

    # Write CSV
    with open(OUTPUT_FILE, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=scored[0].keys())
        writer.writeheader()
        writer.writerows(scored)

    # Summary
    waves = {"Wave-1": 0, "Wave-2": 0, "Wave-3": 0}
    for s in scored:
        waves[s["Wave"]] = waves.get(s["Wave"], 0) + 1

    print(f"\nWave assignment complete:")
    print(f"  Wave-1 (simple, migrate first):  {waves['Wave-1']} servers")
    print(f"  Wave-2 (standard):               {waves['Wave-2']} servers")
    print(f"  Wave-3 (complex, migrate last):  {waves['Wave-3']} servers")
    print(f"\nOutput: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
