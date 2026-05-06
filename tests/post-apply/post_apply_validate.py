#!/usr/bin/env python3
"""
Post-apply infrastructure validation.
Runs after every terraform apply to confirm deployed resources match
the intended configuration and pass connectivity/security requirements.

Usage:
    python post_apply_validate.py --env prod --subscription <sub-id>
"""
import argparse
import sys

from azure.identity import DefaultAzureCredential
from azure.mgmt.network import NetworkManagementClient
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.monitor import MonitorManagementClient

parser = argparse.ArgumentParser()
parser.add_argument("--subscription", required=True)
parser.add_argument("--env", required=True)
args = parser.parse_args()

cred    = DefaultAzureCredential()
net_cl  = NetworkManagementClient(cred, args.subscription)
res_cl  = ResourceManagementClient(cred, args.subscription)
mon_cl  = MonitorManagementClient(cred, args.subscription)

results = []


def check(name: str, fn) -> None:
    try:
        ok, detail = fn()
        status = "PASS" if ok else "FAIL"
        print(f"  [{status}] {name}: {detail}")
        results.append((name, ok))
    except Exception as e:
        print(f"  [FAIL] {name}: EXCEPTION — {e}")
        results.append((name, False))


# ── Checks ───────────────────────────────────────────────────────────────────

def check_hub_vnet():
    vnets = list(net_cl.virtual_networks.list_all())
    hub   = next((v for v in vnets if "hub" in v.name.lower()), None)
    return (hub is not None, hub.name if hub else "Hub VNet not found")


def check_firewall():
    fws = list(net_cl.azure_firewalls.list_all())
    fw  = next((f for f in fws if f.provisioning_state == "Succeeded"), None)
    return (fw is not None, fw.name if fw else "No provisioned Azure Firewall found")


def check_no_public_ips_on_vms():
    nics       = list(net_cl.network_interfaces.list_all())
    violations = []
    for nic in nics:
        if nic.virtual_machine:
            for ipc in (nic.ip_configurations or []):
                if ipc.public_ip_address:
                    violations.append(nic.name)
    return (
        len(violations) == 0,
        "All VMs private — no public IPs" if not violations
        else f"Public IPs attached to NICs: {violations}",
    )


def check_peerings_connected():
    vnets  = list(net_cl.virtual_networks.list_all())
    broken = []
    for vn in vnets:
        rg = vn.id.split("/")[4]
        for peer in net_cl.virtual_network_peerings.list(rg, vn.name):
            if peer.peering_state != "Connected":
                broken.append(f"{vn.name}/{peer.name} [{peer.peering_state}]")
    return (
        len(broken) == 0,
        "All VNet peerings connected" if not broken else f"Broken peerings: {broken}",
    )


def check_firewall_policy():
    policies = list(net_cl.firewall_policies.list_all())
    premium  = [p for p in policies if p.sku and p.sku.tier == "Premium"]
    return (
        len(premium) > 0,
        f"Premium policy: {premium[0].name}" if premium else "No Premium firewall policy found",
    )


# ── Run all checks ────────────────────────────────────────────────────────────
print(f"\nPost-apply validation — environment: {args.env}\n")

check("Hub VNet exists",              check_hub_vnet)
check("Azure Firewall provisioned",   check_firewall)
check("Firewall Policy Premium tier", check_firewall_policy)
check("No public IPs on VMs",         check_no_public_ips_on_vms)
check("All VNet peerings connected",  check_peerings_connected)

# ── Summary ───────────────────────────────────────────────────────────────────
failed = [r[0] for r in results if not r[1]]
total  = len(results)
passed = total - len(failed)

print(f"\n{passed}/{total} checks passed.")

if failed:
    print(f"FAILED: {failed}")
    sys.exit(1)

print("All post-apply validations passed.\n")
