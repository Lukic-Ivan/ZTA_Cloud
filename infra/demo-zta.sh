#!/bin/bash

echo "==========================================================="
echo "=== Pokretanje servisa za ZTA demonstraciju ==="
echo "==========================================================="
cd /home/ivan/Vault/Programiranje/ZTA_Cloud
kubectl port-forward svc/auth-service 4000:4000 -n zta-demo > /dev/null 2>&1 &
AUTH_PID=$!
kubectl port-forward svc/backend 3000:3000 -n zta-demo > /dev/null 2>&1 &
BACKEND_PID=$!

sleep 3

echo -e "\n-----------------------------------------------------------"
echo "=== 1. ZTA Princip: Nema pristupa po default-u (Bez Tokena)"
echo "Ocekivano: Pristup odbijen (403)"
echo "-----------------------------------------------------------"
curl -s -w "\nHTTP Status: %{http_code}\n" http://localhost:3000/api/data

echo -e "\n-----------------------------------------------------------"
echo "=== 2. Eksplicitna verifikacija: Login kao 'user'"
echo "Dobijamo JWT od Auth Servisa"
echo "-----------------------------------------------------------"
RESPONSE=$(curl -s -X POST http://localhost:4000/api/login -H "Content-Type: application/json" -d '{"username": "user", "password": "password123"}')
echo "Odgovor Auth Servisa:"
echo $RESPONSE
USER_TOKEN=$(echo $RESPONSE | grep -o '"token":"[^"]*' | grep -o '[^"]*$')

echo -e "\n-----------------------------------------------------------"
echo "=== 3. Pristup backendu sa dobijenim tokenom (Eksplicitna verifikacija RADI)"
echo "Ocekivano: Uspesan pristup (200)"
echo "-----------------------------------------------------------"
curl -s -w "\nHTTP Status: %{http_code}\n" -H "Authorization: Bearer $USER_TOKEN" http://localhost:3000/api/data

echo -e "\n-----------------------------------------------------------"
echo "=== 4. ZTA Princip: Najmanje privilegije (Least Privilege)"
echo "Pokusaj da 'user' pristupi /api/admin-data"
echo "Ocekivano: Pristup odbijen (403)"
echo "-----------------------------------------------------------"
curl -s -w "\nHTTP Status: %{http_code}\n" -H "Authorization: Bearer $USER_TOKEN" http://localhost:3000/api/admin-data

echo -e "\n-----------------------------------------------------------"
echo "=== 5. Login kao 'admin' i pristup /api/admin-data"
echo "Ocekivano: Uspesan pristup (200)"
echo "-----------------------------------------------------------"
RESPONSE_ADMIN=$(curl -s -X POST http://localhost:4000/api/login -H "Content-Type: application/json" -d '{"username": "admin", "password": "password123"}')
ADMIN_TOKEN=$(echo $RESPONSE_ADMIN | grep -o '"token":"[^"]*' | grep -o '[^"]*$')
curl -s -w "\nHTTP Status: %{http_code}\n" -H "Authorization: Bearer $ADMIN_TOKEN" http://localhost:3000/api/admin-data

kill $AUTH_PID
kill $BACKEND_PID
wait $AUTH_PID 2>/dev/null
wait $BACKEND_PID 2>/dev/null
echo "Gotovo."
