#!/usr/bin/env python3
"""
cost_report.py — Relatório de custos AWS via Cost Explorer API
Uso: python cost_report.py --days 30 [--output relatorio.html]
"""

import argparse
import json
from datetime import datetime, timedelta
from collections import defaultdict

import boto3


def get_cost_by_service(ce_client, start_date: str, end_date: str) -> dict:
    """Retorna custos agrupados por serviço AWS."""
    response = ce_client.get_cost_and_usage(
        TimePeriod={"Start": start_date, "End": end_date},
        Granularity="MONTHLY",
        Metrics=["UnblendedCost"],
        GroupBy=[{"Type": "DIMENSION", "Key": "SERVICE"}],
    )

    costs = {}
    for result in response["ResultsByTime"]:
        for group in result["Groups"]:
            service = group["Keys"][0]
            amount = float(group["Metrics"]["UnblendedCost"]["Amount"])
            costs[service] = costs.get(service, 0) + amount

    return dict(sorted(costs.items(), key=lambda x: x[1], reverse=True))


def get_cost_by_tag(ce_client, start_date: str, end_date: str, tag_key: str = "env") -> dict:
    """Retorna custos agrupados por tag."""
    response = ce_client.get_cost_and_usage(
        TimePeriod={"Start": start_date, "End": end_date},
        Granularity="MONTHLY",
        Metrics=["UnblendedCost"],
        GroupBy=[{"Type": "TAG", "Key": tag_key}],
    )

    costs = {}
    for result in response["ResultsByTime"]:
        for group in result["Groups"]:
            tag_value = group["Keys"][0].replace(f"{tag_key}$", "") or "sem-tag"
            amount = float(group["Metrics"]["UnblendedCost"]["Amount"])
            costs[tag_value] = costs.get(tag_value, 0) + amount

    return dict(sorted(costs.items(), key=lambda x: x[1], reverse=True))


def get_daily_trend(ce_client, start_date: str, end_date: str) -> list:
    """Retorna tendência diária de custos."""
    response = ce_client.get_cost_and_usage(
        TimePeriod={"Start": start_date, "End": end_date},
        Granularity="DAILY",
        Metrics=["UnblendedCost"],
    )

    trend = []
    for result in response["ResultsByTime"]:
        trend.append({
            "date": result["TimePeriod"]["Start"],
            "cost": float(result["Total"]["UnblendedCost"]["Amount"]),
        })

    return trend


def get_savings_recommendations(ce_client) -> list:
    """Retorna recomendações de Savings Plans."""
    try:
        response = ce_client.get_savings_plans_purchase_recommendation(
            SavingsPlansType="COMPUTE_SP",
            TermInYears="ONE_YEAR",
            PaymentOption="NO_UPFRONT",
            LookbackPeriodInDays="THIRTY_DAYS",
        )
        recs = response.get("SavingsPlansPurchaseRecommendation", {})
        summary = recs.get("SavingsPlansPurchaseRecommendationSummary", {})
        return {
            "estimated_monthly_savings": summary.get("EstimatedMonthlySavingsAmount", "0"),
            "estimated_savings_percentage": summary.get("EstimatedSavingsPercentage", "0"),
            "recommended_hourly_commitment": summary.get("HourlyCommitmentToPurchase", "0"),
        }
    except Exception:
        return {}


def print_report(costs_by_service: dict, costs_by_tag: dict, trend: list, savings: dict):
    """Imprime relatório formatado no terminal."""
    total = sum(costs_by_service.values())

    print("\n" + "=" * 60)
    print("  💰 RELATÓRIO DE CUSTOS AWS")
    print("=" * 60)

    print(f"\n📊 TOTAL DO PERÍODO: $ {total:.2f} USD\n")

    print("🔝 TOP 10 SERVIÇOS POR CUSTO:")
    print("-" * 40)
    for service, cost in list(costs_by_service.items())[:10]:
        pct = (cost / total * 100) if total > 0 else 0
        bar = "█" * int(pct / 2)
        print(f"  {service:<35} $ {cost:>8.2f}  {pct:>5.1f}%  {bar}")

    print("\n🏷️  CUSTOS POR TAG 'env':")
    print("-" * 40)
    for tag, cost in costs_by_tag.items():
        print(f"  {tag:<20} $ {cost:.2f}")

    if savings:
        print("\n💡 RECOMENDAÇÕES DE SAVINGS PLANS:")
        print("-" * 40)
        print(f"  Economia estimada/mês: $ {float(savings.get('estimated_monthly_savings', 0)):.2f}")
        print(f"  Percentual de economia: {savings.get('estimated_savings_percentage', 0)}%")

    print("\n" + "=" * 60)


def main():
    parser = argparse.ArgumentParser(description="Relatório de custos AWS")
    parser.add_argument("--days", type=int, default=30, help="Número de dias para análise")
    parser.add_argument("--output", type=str, help="Arquivo de saída HTML (opcional)")
    parser.add_argument("--region", type=str, default="us-east-1")
    args = parser.parse_args()

    end_date = datetime.today().strftime("%Y-%m-%d")
    start_date = (datetime.today() - timedelta(days=args.days)).strftime("%Y-%m-%d")

    print(f"📅 Período: {start_date} → {end_date}")

    # Cost Explorer só está disponível em us-east-1
    ce_client = boto3.client("ce", region_name="us-east-1")

    costs_by_service = get_cost_by_service(ce_client, start_date, end_date)
    costs_by_tag = get_cost_by_tag(ce_client, start_date, end_date)
    trend = get_daily_trend(ce_client, start_date, end_date)
    savings = get_savings_recommendations(ce_client)

    print_report(costs_by_service, costs_by_tag, trend, savings)

    if args.output:
        # Salvar dados brutos em JSON para uso externo
        report_data = {
            "period": {"start": start_date, "end": end_date},
            "total": sum(costs_by_service.values()),
            "by_service": costs_by_service,
            "by_tag": costs_by_tag,
            "daily_trend": trend,
            "savings_recommendations": savings,
        }
        with open(args.output.replace(".html", ".json"), "w") as f:
            json.dump(report_data, f, indent=2)
        print(f"\n✅ Relatório salvo em: {args.output.replace('.html', '.json')}")


if __name__ == "__main__":
    main()
