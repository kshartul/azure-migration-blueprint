#!/usr/bin/env python3
"""
Post-cutover smoke test suite.
Validates each migrated VM after cutover — must all pass before
cutover is declared complete.

Usage:
    python run_wave_smoke_tests.py \
        --vms "vm-app01,vm-app02,vm-db01" \
        --subscription <sub-id>
"""
import argparse
import socket
import sys

from azure.identity import DefaultAzureCredential
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.network import NetworkManagementClient

parser = argparse.ArgumentParser()
parser.add_argument("--vms",          required=True,  help="Comma-separated VM names")
parser.add_argument("--subscription", required=True)
parser.add_argument("--rg",           required=False, default="")
args = parser.parse_args()

cred    = DefaultAzureCredential()
compute = ComputeManagementClient(cred, args.subscription)
network = NetworkManagementClient(cred, args.subscription)
vms     = [v.strip() for v in args.vms.split(",")]
results = []


def test(name: str, fn) -> None:
    try:
        ok, detail = fn()
        status = "PASS" if ok else "FAIL"
        print(f"  [{status}] {name}: {detail}")
        results.append((name, ok))
    except Exception as e:
        print(f"  [FAIL] {name}: {e}")
        results.append((name, False))


for vm_name in vms:
    print(f"\n─── Smoke tests: {vm_name} ───")

    # 1. VM in running state
    def vm_running(n=vm_name):
        all_vms = list(compute.virtual_machines.list_all())
        vm = next((v for v in all_vms if v.name == n), None)
        if not vm:
            return False, "VM not found in subscription"
        rg = vm.id.split("/")[4]
        iv = compute.virtual_machines.instance_view(rg, n)
        states = [s.code for s in iv.statuses]
        running = any("running" in s for s in states)
        return running, " | ".join(states)
    test("VM in running state", vm_running)

    # 2. DNS resolves
    def dns_resolves(n=vm_name):
        try:
            ip = socket.gethostbyname(n)
            return True, f"Resolves to {ip}"
        except socket.gaierror as e:
            return False, str(e)
    test("DNS resolution", dns_resolves)

    # 3. Management port reachable (SSH or RDP)
    def port_reachable(n=vm_name):
        for port in [22, 3389]:
            s = socket.socket()
            s.settimeout(5)
            if s.connect_ex((n, port)) == 0:
                s.close()
                return True, f"Port {port} reachable"
        return False, "Neither SSH (22) nor RDP (3389) reachable"
    test("Management port reachable", port_reachable)

    # 4. No public IP on NIC
    def no_public_ip(n=vm_name):
        nics = list(network.network_interfaces.list_all())
        vm_nics = [nic for nic in nics
                   if nic.virtual_machine and n in (nic.virtual_machine.id or "")]
        for nic in vm_nics:
            for ipc in (nic.ip_configurations or []):
                if ipc.public_ip_address:
                    return False, f"Public IP on NIC {nic.name}"
        return True, "No public IPs — all private"
    test("No public IP attached", no_public_ip)

    # 5. NIC connected to expected private network
    def nic_in_private_subnet(n=vm_name):
        nics = list(network.network_interfaces.list_all())
        vm_nics = [nic for nic in nics
                   if nic.virtual_machine and n in (nic.virtual_machine.id or "")]
        if not vm_nics:
            return False, "No NICs found for VM"
        ips = [ipc.private_ip_address for nic in vm_nics
               for ipc in (nic.ip_configurations or []) if ipc.private_ip_address]
        return len(ips) > 0, f"Private IPs: {', '.join(ips)}"
    test("NIC has private IP", nic_in_private_subnet)


# ── Summary ────────────────────────────────────────────────────────────────
failed = [r[0] for r in results if not r[1]]
total  = len(results)
passed = total - len(failed)

print(f"\nSmoke tests: {passed}/{total} passed.")

if failed:
    print(f"FAILED checks: {failed}")
    sys.exit(1)

print("All smoke tests passed. Cutover validated.\n")
