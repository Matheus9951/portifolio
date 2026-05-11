#!/usr/bin/env python3
"""
idle_resources.py — Identifica recursos AWS ociosos para otimização de custos.
Verifica: EC2 com baixo CPU, EBS não anexados, EIPs não utilizados, snapshots antigos.
"""

import boto3
from datetime import datetime, timedelta, timezone


def find_idle_ec2(ec2_client, cloudwatch_client, cpu_threshold: float = 5.0) -> list:
    """
    Encontra instâncias EC2 com CPU médio abaixo do threshold nos últimos 7 dias.
    Candidatas a downsize ou desligamento.
    """
    idle = []
    paginator = ec2_client.get_paginator("describe_instances")

    for page in paginator.paginate(Filters=[{"Name": "instance-state-name", "Values": ["running"]}]):
        for reservation in page["Reservations"]:
            for instance in reservation["Instances"]:
                instance_id = instance["InstanceId"]
                instance_type = instance["InstanceType"]
                name = next(
                    (tag["Value"] for tag in instance.get("Tags", []) if tag["Key"] == "Name"),
                    "sem-nome"
                )

                # Buscar CPU médio dos últimos 7 dias
                end_time = datetime.now(timezone.utc)
                start_time = end_time - timedelta(days=7)

                metrics = cloudwatch_client.get_metric_statistics(
                    Namespace="AWS/EC2",
                    MetricName="CPUUtilization",
                    Dimensions=[{"Name": "InstanceId", "Value": instance_id}],
                    StartTime=start_time,
                    EndTime=end_time,
                    Period=86400,  # 1 dia
                    Statistics=["Average"],
                )

                if metrics["Datapoints"]:
                    avg_cpu = sum(d["Average"] for d in metrics["Datapoints"]) / len(metrics["Datapoints"])
                    if avg_cpu < cpu_threshold:
                        idle.append({
                            "resource": "EC2",
                            "id": instance_id,
                            "name": name,
                            "type": instance_type,
                            "avg_cpu_7d": round(avg_cpu, 2),
                            "recommendation": f"CPU médio {avg_cpu:.1f}% — considere downsize ou desligamento",
                        })

    return idle


def find_unattached_ebs(ec2_client) -> list:
    """Encontra volumes EBS não anexados a nenhuma instância."""
    idle = []
    paginator = ec2_client.get_paginator("describe_volumes")

    for page in paginator.paginate(Filters=[{"Name": "status", "Values": ["available"]}]):
        for volume in page["Volumes"]:
            name = next(
                (tag["Value"] for tag in volume.get("Tags", []) if tag["Key"] == "Name"),
                "sem-nome"
            )
            idle.append({
                "resource": "EBS",
                "id": volume["VolumeId"],
                "name": name,
                "size_gb": volume["Size"],
                "type": volume["VolumeType"],
                "created": volume["CreateTime"].strftime("%Y-%m-%d"),
                "recommendation": "Volume não anexado — verifique se pode ser deletado",
            })

    return idle


def find_unused_eips(ec2_client) -> list:
    """Encontra Elastic IPs não associados (geram custo sem uso)."""
    idle = []
    response = ec2_client.describe_addresses()

    for address in response["Addresses"]:
        if "AssociationId" not in address:
            idle.append({
                "resource": "EIP",
                "id": address["AllocationId"],
                "ip": address["PublicIp"],
                "recommendation": "EIP não associado — libere para evitar cobrança",
            })

    return idle


def find_old_snapshots(ec2_client, days_old: int = 90) -> list:
    """Encontra snapshots EBS mais antigos que X dias."""
    idle = []
    cutoff = datetime.now(timezone.utc) - timedelta(days=days_old)

    paginator = ec2_client.get_paginator("describe_snapshots")
    for page in paginator.paginate(OwnerIds=["self"]):
        for snapshot in page["Snapshots"]:
            if snapshot["StartTime"] < cutoff:
                name = next(
                    (tag["Value"] for tag in snapshot.get("Tags", []) if tag["Key"] == "Name"),
                    "sem-nome"
                )
                idle.append({
                    "resource": "Snapshot",
                    "id": snapshot["SnapshotId"],
                    "name": name,
                    "size_gb": snapshot["VolumeSize"],
                    "created": snapshot["StartTime"].strftime("%Y-%m-%d"),
                    "recommendation": f"Snapshot com mais de {days_old} dias — avalie exclusão",
                })

    return idle


def print_findings(findings: list):
    """Imprime os recursos ociosos encontrados."""
    if not findings:
        print("  ✅ Nenhum recurso ocioso encontrado.")
        return

    for item in findings:
        print(f"  ⚠️  [{item['resource']}] {item['id']} — {item.get('name', '')}")
        print(f"      → {item['recommendation']}")


def main():
    region = "us-east-1"
    ec2 = boto3.client("ec2", region_name=region)
    cw = boto3.client("cloudwatch", region_name=region)

    print("\n" + "=" * 60)
    print("  🔍 ANÁLISE DE RECURSOS OCIOSOS — FinOps")
    print("=" * 60)

    print("\n🖥️  EC2 com baixo uso de CPU (< 5% nos últimos 7 dias):")
    print_findings(find_idle_ec2(ec2, cw))

    print("\n💾 Volumes EBS não anexados:")
    print_findings(find_unattached_ebs(ec2))

    print("\n🌐 Elastic IPs não utilizados:")
    print_findings(find_unused_eips(ec2))

    print("\n📸 Snapshots com mais de 90 dias:")
    print_findings(find_old_snapshots(ec2))

    print("\n" + "=" * 60)


if __name__ == "__main__":
    main()
