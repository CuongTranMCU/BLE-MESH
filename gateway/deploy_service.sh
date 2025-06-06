#!/bin/bash
echo "📦 Deploying ble_gateway.service..."
sudo cp ~/Code/BLE-MESH/gateway/ble_gateway.service /etc/systemd/system/ble_gateway.service
sudo systemctl daemon-reload
sudo systemctl restart ble_gateway.service
echo "✅ Done. Service restarted."
