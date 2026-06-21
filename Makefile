.PHONY: cluster deploy shutdown destroy images demo-lateral-movement demo-privilege-escalation demo-auth

cluster:
	./infra/cluster-setup.sh


images:
	minikube image build --all -t zta-backend:local apps/backend
	minikube image build --all -t zta-frontend:local apps/frontend
	minikube image build --all -t zta-auth-service:local apps/auth-service

deploy: images
	kubectl apply -f k8s/01-namespace.yaml
	kubectl apply -f k8s/02-rbac.yaml
	kubectl apply -f k8s/04-network-policies.yaml
	kubectl apply -f k8s/05-kyverno-policies.yaml
	kubectl apply -f k8s/06-monitoring.yaml
	kubectl apply -f k8s/03-apps.yaml
	kubectl apply -f k8s/07-auth-service.yaml
	kubectl rollout restart deployment/database deployment/backend deployment/frontend deployment/auth-service -n zta-demo
	kubectl rollout status deployment/database -n zta-demo
	kubectl rollout status deployment/backend -n zta-demo
	kubectl rollout status deployment/frontend -n zta-demo
	kubectl rollout status deployment/auth-service -n zta-demo

shutdown:
	bash ./infra/shutdown.sh

destroy:
	minikube delete

demo-lateral:
	@echo "Pokusaj pristupanja bazi sa frontenda (treba da bude timeout jer nema permisije za rutu):"
	kubectl exec -it -n zta-demo deploy/frontend -- wget --timeout=3 -qO- database:6379 || echo " Pristup ODBIJEN NetworkPolicy-em!"

demo-privilege:
	@echo "Pokusaj kreiranja privilegovanog poda (treba da propadne na AdmissionControlleru obzirom na Kyverno):"
	kubectl run rogue-pod -n zta-demo --image=alpine --overrides='{"spec": {"containers": [{"name": "rogue-pod", "image": "alpine", "securityContext": {"privileged": true}}]}}' || echo "Kreiranje ODBIJENO od strane Kyverno enginea!"

demo-api:
	@echo "Testiranje API prolaza (dobar request):"
	kubectl exec -n zta-demo deploy/frontend -- node -e "const http=require('http'); const req=http.get('http://127.0.0.1:8080/', r => { let data=''; r.on('data', c => data += c); r.on('end', () => { console.log(data); process.exit(0); }); }); req.on('error', e => { console.error(e.message); process.exit(1); }); req.setTimeout(5000, () => { console.error('timeout'); req.destroy(); process.exit(2); });"

demo-monitoring:
	@echo "Pokretanje port-forwarda za Grafanu na http://localhost:3000"
	@echo "Pristupite koristeći kredencijale: admin / prom-operator"
	kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring

demo-auth:
	@echo "Pokretanje demonstracije ZTA autentifikacije i autorizacije..."
	./infra/demo-zta.sh
