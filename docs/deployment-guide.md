# Руководство по деплою NCV Stack

> **NCV** = Nomad + Consul + Vault + Traefik + Keycloak

## Содержание

1. [Обзор архитектуры](#обзор-архитектуры)
2. [Требования](#требования)
3. [Подготовка инфраструктуры](#подготовка-инфраструктуры)
4. [Деплой HashiCorp Stack](#деплой-hashicorp-stack)
5. [Настройка Traefik и SSL](#настройка-traefik-и-ssl)
6. [Настройка Keycloak (SSO)](#настройка-keycloak-sso)
7. [Интеграция сервисов с Keycloak](#интеграция-сервисов-с-keycloak)
8. [Траблшутинг](#траблшутинг)
9. [Полезные команды](#полезные-команды)
10. [Чеклисты](#чеклисты)

---

## Обзор архитектуры

### Общая схема

```
                         Internet
                            │
                            ▼
                    ┌───────────────┐
                    │  Cloudflare   │
                    │   DNS/CDN     │
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │ Load Balancer │
                    │  VIP: x.x.x.x │
                    │ (Keepalived)  │
                    └───────┬───────┘
                            │
           ┌────────────────┼────────────────┐
           │                │                │
           ▼                ▼                ▼
    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
    │  Worker 1   │  │  Worker 2   │  │  Worker N   │
    │             │  │             │  │             │
    │ • Traefik   │  │ • Traefik   │  │ • Traefik   │
    │ • Consul    │  │ • Consul    │  │ • Consul    │
    │ • Nomad     │  │ • Nomad     │  │ • Nomad     │
    │ • Docker    │  │ • Docker    │  │ • Docker    │
    └─────────────┘  └─────────────┘  └─────────────┘
```

### Компоненты стека

| Компонент | Назначение | Порты |
|-----------|------------|-------|
| **Traefik** | Reverse Proxy, SSL termination, Load Balancing | 80, 443, 8080 |
| **Keycloak** | Identity Provider, SSO, OIDC | 8180 |
| **Vault** | Secrets Management, PKI | 8200 |
| **Consul** | Service Discovery, KV Store | 8500, 8501 |
| **Nomad** | Container Orchestration | 4646 |
| **Forward-auth** | OIDC Middleware для Traefik | 4181 |

### Сервисы и домены

| Домен | Сервис | Авторизация |
|-------|--------|-------------|
| `traefik.domain.com` | Traefik Dashboard | Keycloak OIDC |
| `keycloak.domain.com` | Keycloak Admin | Встроенная |
| `vault.domain.com` | Vault UI/API | OIDC / Token |
| `*.domain.com` | Другие сервисы | Keycloak OIDC (опционально) |

---

## Требования

### Инфраструктура

| Компонент | Минимум | Рекомендуется |
|-----------|---------|---------------|
| Серверы (мастер) | 1 | 3 (нечётное число) |
| Воркеры | 1 | 2+ |
| RAM на сервер | 4GB | 8GB+ |
| CPU на сервер | 2 vCPU | 4+ vCPU |
| Диск | 20GB | 50GB+ SSD |

### Сети и порты

| Сервис | Порт | Протокол | Назначение |
|--------|------|----------|------------|
| HTTP | 80 | TCP | Redirect to HTTPS |
| HTTPS | 443 | TCP | Web Traffic |
| Traefik API | 8080 | TCP | Dashboard (internal) |
| Keycloak | 8180 | TCP | Identity Provider |
| Vault | 8200 | TCP | Secrets |
| Forward-auth | 4181 | TCP | OIDC Middleware |
| Consul HTTP(S) | 8500/8501 | TCP | Service Discovery |
| Consul RPC | 8300 | TCP | Server communication |
| Consul Serf | 8301 | TCP/UDP | Gossip |
| Nomad HTTP | 4646 | TCP | Orchestration |
| Nomad RPC | 4647 | TCP | Internal |

### Внешние зависимости

- **Домен** с доступом к DNS записям
- **Cloudflare** аккаунт (для DNS challenge)
- **Ansible** 2.14+
- **Python** 3.9+

```bash
# Установка зависимостей Ansible
ansible-galaxy collection install community.crypto
pip install -r requirements-dev.txt
```

---

## Подготовка инфраструктуры

### 1. Настройка DNS (Cloudflare)

Создайте A-записи для всех доменов, указывающих на VIP:

```
traefik.domain.com    A    <VIP_ADDRESS>
keycloak.domain.com   A    <VIP_ADDRESS>
vault.domain.com      A    <VIP_ADDRESS>
```

### 2. Получение Cloudflare API Token

1. Откройте [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens)
2. Create Token → Edit zone DNS (template)
3. Zone Resources: Include → Specific zone → ваш домен
4. Сохраните токен

### 3. Настройка inventory

Создайте `inventories/<cluster>/hosts.yml`:

```yaml
all:
  vars:
    ansible_user: your_user
    ansible_become_password: "your_sudo_password"
    cluster_name: "production"
    cluster_domain: "domain.com"
    
    # VIP для Load Balancer
    cluster_vip: "10.0.0.100"
    
    # Cloudflare
    cloudflare_api_token: "your_cloudflare_token"
    acme_email: "admin@domain.com"
    
    # Consul
    consul_datacenter: "dc1"
    consul_acl_enabled: true
    
    # Версии
    consul_version: "1.22.2"
    vault_version: "1.16.1"
    nomad_version: "1.11.1"
    traefik_version: "v3.0"
    keycloak_version: "24.0.4"

consul_servers:
  hosts:
    master-1:
      node_ip: 10.0.0.1
      ansible_host: 10.0.0.1

consul_clients:
  hosts:
    worker-1:
      node_ip: 10.0.0.11
      ansible_host: 10.0.0.11
    worker-2:
      node_ip: 10.0.0.12
      ansible_host: 10.0.0.12

vault_servers:
  hosts:
    master-1:

nomad_servers:
  hosts:
    master-1:

nomad_clients:
  hosts:
    worker-1:
    worker-2:
```

### 4. Настройка /etc/hosts на воркерах

На каждом воркере добавьте записи для внутреннего резолва:

```bash
echo "<VIP> keycloak.domain.com vault.domain.com traefik.domain.com" | sudo tee -a /etc/hosts
```

---

## Деплой HashiCorp Stack

### Шаг 1: Генерация PKI сертификатов

```bash
ansible-playbook -i inventories/<cluster>/hosts.yml site.yml --tags pki
```

### Шаг 2: Деплой Consul

```bash
ansible-playbook -i inventories/<cluster>/hosts.yml site.yml --tags consul
```

Bootstrap ACL:
```bash
export CONSUL_HTTP_ADDR=https://127.0.0.1:8501
export CONSUL_CACERT=/etc/consul.d/tls/ca.pem
consul acl bootstrap
# Сохраните SecretID!
```

### Шаг 3: Деплой Nomad

```bash
ansible-playbook -i inventories/<cluster>/hosts.yml site.yml --tags nomad
```

---

## Настройка Traefik и SSL

### Шаг 1: Деплой Traefik через Nomad

Используйте job файл `jobs/enabled/traefik-lb.hcl`. Основные параметры:

```hcl
job "traefik" {
  datacenters = ["dc1"]
  type = "system"

  group "traefik" {
    network {
      mode = "host"
      port "http" { static = 80 }
      port "https" { static = 443 }
      port "traefik" { static = 8080 }
    }

    task "traefik" {
      driver = "docker"

      config {
        image = "traefik:v3.0"
        network_mode = "host"
        volumes = [
          "local/traefik.yml:/etc/traefik/traefik.yml",
          "local/dynamic:/etc/traefik/dynamic",
          "local/acme:/etc/traefik/acme"
        ]
      }

      env {
        CF_DNS_API_TOKEN = "<CLOUDFLARE_TOKEN>"
        ACME_EMAIL = "admin@domain.com"
      }
    }
  }
}
```

> Примечание: Traefik по умолчанию подключается к Consul/Vault через mTLS и
> ожидает сертификаты на хосте в `/etc/consul.d/tls` и `/etc/vault.d/tls`
> (они монтируются в `/secrets/consul` и `/secrets/vault` внутри контейнера).
> При необходимости переопределите `consul_tls_*_src` и `vault_tls_*_src`
> в job файле.

### Шаг 2: Создание dynamic config

Создайте файл конфигурации в директории `dynamic/config.yml`:

```yaml
http:
  middlewares:
    keycloak-auth:
      forwardAuth:
        address: "http://127.0.0.1:4181"
        trustForwardHeader: true
        authResponseHeaders:
          - X-Forwarded-User

    security-headers:
      headers:
        frameDeny: true
        browserXssFilter: true
        contentTypeNosniff: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 31536000

  routers:
    # Traefik Dashboard с Keycloak авторизацией
    dashboard:
      rule: "Host(`traefik.domain.com`)"
      entryPoints:
        - websecure
      service: api@internal
      middlewares:
        - keycloak-auth
        - security-headers
      tls:
        certResolver: letsencrypt

    # Keycloak - БЕЗ авторизации (сам является IdP)
    keycloak:
      rule: "Host(`keycloak.domain.com`)"
      entryPoints:
        - websecure
      service: keycloak
      tls:
        certResolver: letsencrypt

    # Vault - собственная OIDC авторизация
    vault:
      rule: "Host(`vault.domain.com`)"
      entryPoints:
        - websecure
      service: vault
      middlewares:
        - security-headers
      tls:
        certResolver: letsencrypt

  services:
    keycloak:
      loadBalancer:
        servers:
          - url: "http://<KEYCLOAK_HOST>:8180"
    
    vault:
      loadBalancer:
        servers:
          - url: "http://<VAULT_HOST>:8200"

tls:
  options:
    default:
      minVersion: VersionTLS12
```

### Шаг 3: Деплой

```bash
nomad job run jobs/enabled/traefik-lb.hcl
```

---

## Настройка Keycloak (SSO)

### Шаг 1: Деплой Keycloak

```bash
docker run -d \
  --name keycloak \
  --restart unless-stopped \
  --network host \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=<SECURE_PASSWORD> \
  -e KC_HTTP_PORT=8180 \
  -e KC_PROXY=edge \
  -e KC_HOSTNAME=keycloak.domain.com \
  -e KC_HOSTNAME_STRICT=false \
  quay.io/keycloak/keycloak:24.0.4 start-dev
```

### Шаг 2: Настройка Realm

1. Откройте https://keycloak.domain.com/admin
2. Войдите как `admin`
3. Create Realm → Name: `ncv`
4. Realm Settings → Frontend URL: `https://keycloak.domain.com`

### Шаг 3: Создание клиентов

#### Клиент для Traefik (forward-auth)

| Параметр | Значение |
|----------|----------|
| Client ID | `traefik` |
| Client authentication | ON |
| Valid redirect URIs | `https://*.domain.com/_oauth` |
| Web origins | `https://*.domain.com` |

#### Клиент для Vault

| Параметр | Значение |
|----------|----------|
| Client ID | `vault` |
| Client authentication | ON |
| Valid redirect URIs | `https://vault.domain.com/ui/vault/auth/oidc/oidc/callback`<br>`https://vault.domain.com/oidc/callback`<br>`http://localhost:8250/oidc/callback` |
| Web origins | `https://vault.domain.com`, `+` |

### Шаг 4: Создание пользователей

1. Users → Add user
2. Email: `user@domain.com`
3. Email verified: ON
4. Credentials → Set password

---

## Интеграция сервисов с Keycloak

### Forward-auth (для Traefik)

Запустите на каждом воркере:

```bash
docker run -d \
  --name forward-auth \
  --restart unless-stopped \
  --network host \
  -e PROVIDERS_OIDC_ISSUER_URL="https://keycloak.domain.com/realms/ncv" \
  -e PROVIDERS_OIDC_CLIENT_ID="traefik" \
  -e PROVIDERS_OIDC_CLIENT_SECRET="<TRAEFIK_CLIENT_SECRET>" \
  -e SECRET="<RANDOM_SECRET_32_CHARS>" \
  -e INSECURE_COOKIE=false \
  -e COOKIE_DOMAIN="domain.com" \
  -e DEFAULT_PROVIDER="oidc" \
  -e LOG_LEVEL="info" \
  -e WHITELIST="user@domain.com,admin@domain.com" \
  thomseddon/traefik-forward-auth:2
```

**Важные параметры:**

| Параметр | Описание |
|----------|----------|
| `WHITELIST` | Список email адресов с доступом (через запятую) |
| `COOKIE_DOMAIN` | Общий домен для cookies |
| `SECRET` | Случайная строка 32+ символов для подписи |

### Vault OIDC

```bash
# Включить OIDC auth
curl -X POST http://127.0.0.1:8200/v1/sys/auth/oidc \
  -H "X-Vault-Token: root" \
  -d '{"type": "oidc"}'

# Настроить OIDC
curl -X PUT http://127.0.0.1:8200/v1/auth/oidc/config \
  -H "X-Vault-Token: root" \
  -d '{
    "oidc_discovery_url": "https://keycloak.domain.com/realms/ncv",
    "oidc_client_id": "vault",
    "oidc_client_secret": "<VAULT_CLIENT_SECRET>",
    "default_role": "default"
  }'

# Создать роль
curl -X PUT http://127.0.0.1:8200/v1/auth/oidc/role/default \
  -H "X-Vault-Token: root" \
  -d '{
    "user_claim": "email",
    "allowed_redirect_uris": [
      "https://vault.domain.com/ui/vault/auth/oidc/oidc/callback",
      "https://vault.domain.com/oidc/callback",
      "http://localhost:8250/oidc/callback"
    ],
    "token_policies": ["default"],
    "token_ttl": "1h"
  }'
```

---

## Траблшутинг

### ERR_TOO_MANY_REDIRECTS

**Симптомы:** Браузер показывает ошибку "слишком много перенаправлений".

**Решение:**
1. Очистите cookies для домена в браузере
2. Проверьте логи: `docker logs forward-auth 2>&1 | tail -20`
3. Убедитесь что redirect_uri совпадает с настройками в Keycloak

### CSRF cookie does not match state

**Симптомы:** 401 Unauthorized при callback.

**Решение:**
1. Полностью очистите cookies для домена
2. Перезапустите браузер или используйте приватный режим

### Bad Gateway / 502

**Симптомы:** Traefik возвращает 502.

**Решение:**
```bash
# Проверьте что backend запущен
docker ps | grep keycloak
curl -I http://localhost:8180/health
```

### Invalid parameter: redirect_uri

**Симптомы:** Keycloak отклоняет авторизацию.

**Решение:**
1. Keycloak Admin → Clients → traefik
2. Добавьте URI в Valid redirect URIs
3. Используйте wildcard: `https://*.domain.com/_oauth`

---

## Полезные команды

### Traefik

```bash
# Логи
docker logs -f traefik

# Список роутеров
curl -s http://localhost:8080/api/http/routers | jq '.[].name'
```

### Keycloak

```bash
# Логи
docker logs -f keycloak

# Health check
curl -s http://localhost:8180/health
```

### Forward-auth

```bash
# Логи (debug)
docker logs -f forward-auth

# Перезапуск
docker restart forward-auth
```

### Vault

```bash
# Статус
curl -s http://localhost:8200/v1/sys/health | jq .

# Список auth methods
curl -s http://localhost:8200/v1/sys/auth -H "X-Vault-Token: root"
```

### SSL проверка

```bash
# Проверка сертификата
echo | openssl s_client -servername domain.com -connect domain.com:443 2>/dev/null | openssl x509 -noout -dates
```

---

## Чеклисты

### Первоначальный деплой

- [ ] DNS записи созданы в Cloudflare
- [ ] Cloudflare API token получен
- [ ] Inventory файл настроен
- [ ] /etc/hosts обновлён на воркерах
- [ ] Consul задеплоен и ACL bootstrap выполнен
- [ ] Nomad задеплоен
- [ ] Traefik задеплоен
- [ ] SSL сертификаты получены
- [ ] Keycloak задеплоен
- [ ] Keycloak realm создан
- [ ] Keycloak клиенты созданы (traefik, vault)
- [ ] Keycloak пользователи созданы
- [ ] Forward-auth запущен на всех воркерах
- [ ] Vault задеплоен
- [ ] Vault OIDC настроен
- [ ] Тест входа через Keycloak

### Добавление нового сервиса

- [ ] Создать роутер в Traefik dynamic config
- [ ] Добавить middleware `keycloak-auth` (если нужна авторизация)
- [ ] Создать service с URL backend
- [ ] Добавить redirect URI в Keycloak (если нужно)
- [ ] Обновить config на всех воркерах
- [ ] Тест доступа

### Безопасность

- [ ] Все пароли уникальные и сложные
- [ ] Root token Vault сохранён безопасно
- [ ] Keycloak admin пароль изменён
- [ ] HTTPS на всех сервисах
- [ ] Whitelist в forward-auth настроен
- [ ] Firewall закрывает прямой доступ к backend портам
- [ ] Backup стратегия определена

---

## Архитектура безопасности

```
┌─────────────────────────────────────────────────────────────────┐
│                         HTTPS Layer                             │
│                    (Let's Encrypt via Cloudflare)               │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Traefik                                 │
│    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐       │
│    │   Router    │    │   Router    │    │   Router    │       │
│    │  traefik.*  │    │  keycloak.* │    │   vault.*   │       │
│    └──────┬──────┘    └──────┬──────┘    └──────┬──────┘       │
│           │                  │                  │               │
│    ┌──────▼──────┐           │           ┌──────▼──────┐       │
│    │ ForwardAuth │           │           │  Security   │       │
│    │ Middleware  │           │           │  Headers    │       │
│    └──────┬──────┘           │           └──────┬──────┘       │
└───────────┼──────────────────┼──────────────────┼───────────────┘
            │                  │                  │
            ▼                  ▼                  ▼
     ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
     │Forward-auth │    │  Keycloak   │    │   Vault     │
     │   :4181     │◄──►│   :8180     │    │   :8200     │
     └─────────────┘    └─────────────┘    └──────┬──────┘
            │                  ▲                  │
            │                  │                  │
            └──────────────────┴──────────────────┘
                         OIDC Flow
```

---

## Ссылки

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Vault Documentation](https://developer.hashicorp.com/vault/docs)
- [Consul Documentation](https://developer.hashicorp.com/consul/docs)
- [Nomad Documentation](https://developer.hashicorp.com/nomad/docs)
- [traefik-forward-auth](https://github.com/thomseddon/traefik-forward-auth)
