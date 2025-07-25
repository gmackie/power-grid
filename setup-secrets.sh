#!/bin/bash

# Setup secrets for Gitea Actions - Power Grid Web Frontend

GITEA_URL="https://ci.gmac.io"
REPO_OWNER="mackieg"
REPO_NAME="power-grid-web"
GITEA_TOKEN="6c0c69be9e3ac745fd234a47e276df22955268ba"

# Check if kubeconfig file exists
if [ ! -f "kubeconfig-base64.txt" ]; then
    echo "Error: kubeconfig-base64.txt not found!"
    echo "Please create this file with your base64-encoded kubeconfig"
    echo "You can create it with: cat ~/.kube/config | base64 > kubeconfig-base64.txt"
    exit 1
fi

# Read kubeconfig from file
KUBECONFIG_BASE64=$(cat kubeconfig-base64.txt)

echo "Adding secrets to Gitea repository: ${REPO_NAME}"
echo "================================================"

# Add GITEATOKEN secret
echo -n "Adding GITEATOKEN secret... "
HTTP_CODE=$(curl -X PUT \
  "${GITEA_URL}/api/v1/repos/${REPO_OWNER}/${REPO_NAME}/actions/secrets/GITEATOKEN" \
  -H "Authorization: token ${GITEA_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"data\": \"${GITEA_TOKEN}\"}" \
  -s -o /dev/null -w "%{http_code}")

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "204" ]; then
    echo "✅ Success (HTTP $HTTP_CODE)"
else
    echo "❌ Failed (HTTP $HTTP_CODE)"
fi

# Add KUBECONFIG secret
echo -n "Adding KUBECONFIG secret... "
HTTP_CODE=$(curl -X PUT \
  "${GITEA_URL}/api/v1/repos/${REPO_OWNER}/${REPO_NAME}/actions/secrets/KUBECONFIG" \
  -H "Authorization: token ${GITEA_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"data\": \"${KUBECONFIG_BASE64}\"}" \
  -s -o /dev/null -w "%{http_code}")

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "204" ]; then
    echo "✅ Success (HTTP $HTTP_CODE)"
else
    echo "❌ Failed (HTTP $HTTP_CODE)"
fi

echo -e "\n✅ Secrets configuration complete!"
echo "================================================"
echo "Deployment will be triggered on next push to main branch"
echo "Check the deployment at: ${GITEA_URL}/${REPO_OWNER}/${REPO_NAME}/actions"
echo ""
echo "Your app will be deployed to: https://power-grid.gmac.io"
echo "WebSocket server expected at: wss://ws.power-grid.gmac.io"