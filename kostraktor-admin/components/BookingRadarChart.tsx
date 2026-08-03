"use client";

import { useEffect, useRef } from "react";
import * as echarts from "echarts";

interface Props {
  pending: number;
  approved: number;
  rejected: number;
}

export default function BookingRadarChart({ pending, approved, rejected }: Props) {
  const chartRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!chartRef.current) return;

    const myChart = echarts.init(chartRef.current);

    // Skala maksimal tiap sumbu dibuat dinamis dari nilai tertinggi,
    // supaya radar tidak gepeng kalau salah satu angka jauh lebih besar.
    const maxVal = Math.max(pending, approved, rejected, 1) * 1.2;

    myChart.setOption({
      tooltip: { trigger: "item" },
      radar: {
        indicator: [
          { name: "Pending", max: maxVal },
          { name: "Disetujui", max: maxVal },
          { name: "Ditolak", max: maxVal },
        ],
        radius: "65%",
      },
      series: [
        {
          type: "radar",
          data: [
            {
              value: [pending, approved, rejected],
              name: "Jumlah Booking",
              areaStyle: { color: "rgba(212, 175, 55, 0.3)" }, // #D4AF37 with opacity
              lineStyle: { color: "#D4AF37", width: 2 },
              itemStyle: { color: "#D4AF37" },
            },
          ],
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
