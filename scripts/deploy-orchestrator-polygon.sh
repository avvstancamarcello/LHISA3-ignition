#!/bin/bash

echo "🕐 Attendo conferme di rete Polygon (2 minuti)..."
sleep 120

echo "🚀 Tentativo deploy OceanMangaOrchestrator..."
npx hardhat ignition deploy ignition/modules/OceanMangaOrchestratorModulePolygon.ts --network polygon

if [ $? -ne 0 ]; then
    echo "❌ Deploy fallito. Attendo altre conferme (1 minuto)..."
    sleep 60
    echo "🔄 Secondo tentativo..."
    npx hardhat ignition deploy ignition/modules/OceanMangaOrchestratorModulePolygon.ts --network polygon
fi