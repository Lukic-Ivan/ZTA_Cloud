# Zero Trust Architecture (ZTA)
Autor: Ivan Lukić 0240/2024
Iz predmeta Cloud infrastruktura i servisi

## Arhitektura demo aplikacije 
Projekat se sastoji od četiri komponente:
- **Frontend** - Node.js aplikacija koja glumi početnu tačku za korisnike (K8s).
- **Backend** - API napisan u Node.js zadužen za biznis logiku (K8s / Lokalno).
- **Database** - Redis NoSQL baza (K8s).
- **Auth-service** - Lokalni servis zadužen isključivo za JWT token autentifikaciju.

## Primenjeni Zero Trust Mehanizmi

1. **Eksplicitna verifikacija i Najmanje privilegije (JWT & RBAC):**
   - Implementiran je *Auth-service* koji izdaje JWT tokene.
   - *Backend* zahteva validan token za svaki pristup i verifikuje ulogu (`user` ili `admin`) pre nego što dozvoli pristup određenom resursu.
2. **Mrežna Segmentacija (NetworkPolicies):** 
   - Postavljen je *Default Deny* na celom `zta-demo` namespace-u unutar klastera.
   - Pravila komunikacije eksplicitno dozvoljavaju isključivo tok: `Frontend -> Backend -> Database`. 
   - Bilo kakav pokušaj preskakanja lanca (npr. *Frontend -> Database*) je striktno blokiran od strane mrežnog kontrolera (Calico).
3. **Infrastrukturne najmanje privilegije (K8s RBAC):** 
   - Umesto deljenog naloga, svaki mikroservis dobija sopstveni `ServiceAccount`.
   - Podrazumevano mountovanje tokena za komuniciranje sa Kubernetes API-jem je pogašeno na nivou podova. 
4. **Policy Enforcement / Admission Control (Kyverno):** 
   - Klaster nadgleda i odbija pokretanje kontejnera koji pokušavaju da dobiju `root` permisije (`runAsNonRoot: true`).
   - Zabranjeno je eskaliranje privilegija kontejnera (`privileged: true`).

## Pokretanje Projekta
Preduslovi: instaliran `make`, `kubectl` i `minikube` na sistemu.

1. **Podizanje klastera:**
   ``` bash
   make cluster
   ```
   Ovo će konfigurisati Minikube, Calico CNI, instalirati Kyverno (Policy Engine) i Prometheus.

2. **Deployovanje Aplikacije:**
   ``` bash
   make deploy
   ```
   Kreiraće docker imidže lokalno i postaviti ih u K8s sa svim propisanim *Network* i *Kyverno* polisama.

## Pokazne vežbe (ZTA u praksi)

Da biste pokazali prednosti ZTA sistema, pokrenite sledeće demo komande:

- **Demo 1: Eksplicitna verifikacija (Aplikativni nivo)**
  Podiže lokalno Auth i Backend servise, i simulira API zahteve sa i bez tokena, kao i eskalaciju uloga.
  ``` bash
  make demo-auth
  ```
  > Rezultat: Aplikacija glatko odbija zahteve bez tokena i zabranjuje običnom "user"-u pristup admin resursima.

- **Demo 2: Lateral Movement (Mrežna K8s segmentacija)**
  Frontend je "hakovan" i napadač pokušava direktno da pogodi bazu (Redis) preskačući backend.
  ``` bash
  make demo-lateral
  ```
  > Rezultat: Konekcija je **odbijena/timeout** zahvaljujući NetworkPolicy *Default-Deny* pravilu.

- **Demo 3: Sprečavanje eskalacije na sistemskom nivou**
  Napadač pokušava da iznutra podigne potpuno privilegovan (*root*) pod na infrastrukturi.
  ``` bash
  make demo-privilege
  ```
  > Rezultat: Kyverno Admission controller blokira upis poda u klaster obzirom da krši propisane bezbednosne K8s polise.
- **Demo 4: Nadgledanje sistema (Grafana)**
  Pristupa se grafani (na portu 3000) i prati se rad sistema.
  ``` bash
  make demo-monitoring
  ```
  > Rezultat: Prikaz dashboard-a za monitoring preko Grafana UI-a.
- **Pristup regularnim rutama (Normalan protok)**
  ```bash
  make demo-api
  ```
  > Rezultat: Frontend uredno šalje zahtev Backend-u i operacija uspeva (kroz dozvoljene NetworkPolicies).

## Upravljanje okruženjem

Ako želite da privremeno ugasite aplikacione podove:
``` bash
make shutdown
```
