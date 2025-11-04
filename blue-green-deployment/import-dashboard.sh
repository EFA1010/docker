#!/bin/bash

# Import Guestbook Business Dashboard into Grafana
# This script imports the business dashboard JSON into Grafana

GRAFANA_URL="http://localhost:3001"
GRAFANA_USER="admin"
GRAFANA_PASSWORD="lpp7xfKcyJuJVCrn20z0tt4kcYd2GQqF6z7VLeqH"

echo "Importing Guestbook Business Dashboard..."

# Import the business dashboard
curl -X POST \
  -H "Content-Type: application/json" \
  -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
  -d @guestbook-business-dashboard.json \
  "${GRAFANA_URL}/api/dashboards/db"

echo ""
echo "Dashboard import completed!"
echo "Access your dashboard at: ${GRAFANA_URL}/d/guestbook-business/guestbook-business-metrics-dashboard"