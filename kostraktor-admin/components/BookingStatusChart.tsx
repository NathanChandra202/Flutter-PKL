"use client";

import { useEffect, useRef } from "react";
import * as echarts from "echarts";

interface Props {
  pending: number;
  approved: number;
  rejected: number;
}

export default function BookingStatusChart({ pending, approved, rejected }: Props) {
  const chartRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!chartRef.current) return;

    const myChart = echarts.init(chartRef.current);

    myChart.setOption({
      animationDuration: 800,
      animationEasing: "cubicOut",
      tooltip: {
        trigger: "axis",
        axisPointer: { type: "shadow" },
        formatter: (params: any) => {
          const p = Array.isArray(params) ? params[0] : params;
          return `${p.name}: ${p.value} booking`;
        },
      },
      grid: { left: 40, right: 20, top: 20, bottom: 30 },
      xAxis: {
        type: "category",
        data: ["Pending", "Disetujui", "Ditolak"],
        axisTick: { show: false },
        axisLine: { lineStyle: { color: "#e5e7eb" } },
        axisLabel: { fontWeight: 600, color: "#64748b" },
      },
      yAxis: {
        type: "value",
        minInterval: 1,
        splitLine: { lineStyle: { color: "#f0f0f0" } },
        axisLabel: { color: "#94a3b8" },
      },
      series: [
        {
          type: "bar",
          data: [
            { value: pending, itemStyle: { color: "#f59e0b" } },
            { value: approved, itemStyle: { color: "#10b981" } },
            { value: rejected, itemStyle: { color: "#ef4444" } },
          ],
          barWidth: "45%",
          itemStyle: { borderRadius: [8, 8, 0, 0] },
          animationDelay: (idx: number) => idx * 120,
        },
      ],
    });

    const handleResize = () => myChart.resize();
    window.addEventListener("resize", handleResize);

    return () => {
      window.removeEventListener("resize", handleResize);
      myChart.dispose();
    };
  }, [pending, approved, rejected]);

  return <div ref={chartRef} style={{ width: "100%", height: "256px" }} />;
}
