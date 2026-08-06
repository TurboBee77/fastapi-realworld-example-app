# fastapi-realworld-example-app — fork (część DevOps)

To jest fork [`nsidnev/fastapi-realworld-example-app`](https://github.com/nsidnev/fastapi-realworld-example-app)
na potrzeby pracy dyplomowej DevOps. Oryginalna dokumentacja aplikacji
(stack, endpointy, uruchomienie lokalne) zostaje w [`README.rst`](README.rst)
bez zmian — ten plik opisuje **wyłącznie** to, co doszło względem
upstreamu na potrzeby CI/CD i monitoringu.

## Co zmieniono względem upstreamu

- **`Jenkinsfile`** — pipeline CI/CD (opis niżej).
- **Endpoint `/metrics`** (`app/main.py`, `prometheus-fastapi-instrumentator`) —
  metryki appki dla Prometheusa.

Nic więcej w kodzie aplikacji nie zostało świadomie ruszone — zakres tego
forka to infrastruktura i CI/CD wokół appki, nie appka sama w sobie.

## Pipeline CI/CD (`Jenkinsfile`)

Wyzwalacz: webhook GitHub (push na dowolną gałąź).

| Stage | Kiedy | Co robi |
|---|---|---|
| `Test` | zawsze | `docker compose` z efemeryczną bazą PostgreSQL, migracja Alembic + `pytest` |
| `Build & Push production image` | zawsze | buduje obraz, publikuje na Docker Hub (`<gałąź>-<sha>`; `latest` dodatkowo na `master`) |
| `Deploy` | tylko `master`, tylko realny push (nie skan gałęzi) | Ansible/SSH aktualizuje kontener aplikacji na docelowej VM |

Powiadomienie o wyniku (sukces/porażka) leci na Discord po każdym buildzie,
niezależnie od tego, na którym stage'u się zatrzymał.

**Gałąź główna: `master`, nie `main`** — odziedziczona z upstreamu, świadomie
nie przemianowana. `when { branch 'master' }` w `Jenkinsfile` jest celowe.

## Infrastruktura i pełna instrukcja wdrożenia

Terraform, Ansible, konfiguracja Jenkinsa i monitoringu żyją w osobnym
repozytorium: [`fastapi-devops-infra`](https://github.com/TurboBee77/fastapi-devops-infra)
— tam pełna instrukcja postawienia całości od zera.
