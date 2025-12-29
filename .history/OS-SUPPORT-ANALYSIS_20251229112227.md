# OS Support Analysis - NCV Project

## 📊 Текущая поддержка операционных систем

### ✅ Debian-based (9.5/10)

#### Ubuntu
- ✅ **22.04 (Jammy)** - Полная поддержка
- ✅ **24.04 (Noble)** - Полная поддержка

#### Debian
- ✅ **11 (Bullseye)** - Документирована
- ✅ **12 (Bookworm)** - Документирована

**Что работает:**
- ✅ APT package management
- ✅ HashiCorp repository (apt.releases.hashicorp.com)
- ✅ GPG key handling
- ✅ ufw firewall (автоматически выбирается)
- ✅ Base packages: curl, unzip, jq, gnupg, ca-certificates, apt-transport-https, openssl
- ✅ Consul, Nomad, Vault установка
- ✅ TLS/PKI поддержка
- ✅ systemd services
- ✅ logrotate

**Ограничения:**
- ⚠️ Docker для Nomad - **НЕ РЕАЛИЗОВАНО** для Debian
- ⚠️ CNI plugins - **НЕ РЕАЛИЗОВАНО** для Debian (только для RHEL)
- ℹ️ Preflight проверяет только Ubuntu версии, не Debian

---

### ✅ RedHat-based (8.5/10)

#### Supported Distributions
- ✅ **Oracle Linux 8, 9** - Полная поддержка
- ✅ **AlmaLinux 8, 9** - Полная поддержка
- ✅ **Rocky Linux 8, 9** - Документирована
- ✅ **RHEL 8, 9** - Документирована

**Что работает:**
- ✅ DNF package management
- ✅ HashiCorp repository (rpm.releases.hashicorp.com)
- ✅ RPM GPG key handling
- ✅ firewalld (автоматически выбирается)
- ✅ Base packages: curl, unzip, jq, gnupg2, ca-certificates, openssl
- ✅ Consul, Nomad, Vault установка
- ✅ TLS/PKI поддержка
- ✅ systemd services
- ✅ logrotate
- ✅ **Docker installation** (специфичная реализация)
- ✅ **CNI plugins** (containernetworking-plugins)
- ✅ Docker CE repository
- ✅ Docker packages: docker-ce, docker-ce-cli, containerd.io, docker-compose-plugin

**Ограничения:**
- ⚠️ Preflight проверяет только OracleLinux и AlmaLinux, не Rocky/RHEL explicit

---

## 🔍 Детальный анализ по компонентам

### 1. Common Role (Base Setup)
| Функция | Debian | RedHat | Статус |
| ------- | ------ | ------ | ------ |
| Package manager | APT | DNF | ✅ Full |
| Base packages | 8 packages | 7 packages | ✅ Full |
| HashiCorp repo | apt.releases | rpm.releases | ✅ Full |
| GPG keys | get_url | rpm_key | ✅ Full |
| Cache management | update_cache | dnf makecache | ✅ Full |
| logrotate | Yes | Yes | ✅ Full |

### 2. Firewall Role
| Функция | Debian | RedHat | Статус |
| ------- | ------ | ------ | ------ |
| Backend | ufw | firewalld | ✅ Full |
| Auto-detect | Yes | Yes | ✅ Full |
| Zone validation | N/A | Yes | ✅ Full |
| Port rules | Yes | Yes | ✅ Full |
| Source restrictions | Yes | Yes | ✅ Full |

### 3. Consul Role
| Функция | Debian | RedHat | Статус |
| ------- | ------ | ------ | ------ |
| Installation | Yes | Yes | ✅ Full |
| TLS support | Yes | Yes | ✅ Full |
| ACL support | Yes | Yes | ✅ Full |
| Gossip encryption | Yes | Yes | ✅ Full |
| systemd service | Yes | Yes | ✅ Full |

### 4. Nomad Role
| Функция | Debian | RedHat | Статус |
| ------- | ------ | ------ | ------ |
| Installation | Yes | Yes | ✅ Full |
| TLS support | Yes | Yes | ✅ Full |
| Consul integration | Yes | Yes | ✅ Full |
| Docker install | **NO** | **YES** | ⚠️ Partial |
| CNI plugins | **NO** | **YES** | ⚠️ Partial |
| systemd service | Yes | Yes | ✅ Full |

**Docker на RHEL:**
```yaml
nomad_install_docker: true  # Works only on RedHat
nomad_docker_repo_url: https://download.docker.com/linux/centos/docker-ce.repo
nomad_docker_packages:
  - dnf-plugins-core
  - docker-ce
  - docker-ce-cli
  - containerd.io
  - docker-compose-plugin
```

**CNI на RHEL:**
```yaml
nomad_install_cni: true  # Works only on RedHat
nomad_cni_packages:
  - containernetworking-plugins
nomad_cni_src_dir: /usr/libexec/cni
nomad_cni_bin_dir: /opt/cni/bin
```

### 5. Vault Role
| Функция | Debian | RedHat | Статус |
| ------- | ------ | ------ | ------ |
| Installation | Yes | Yes | ✅ Full |
| TLS support | Yes | Yes | ✅ Full |
| Consul backend | Yes | Yes | ✅ Full |
| systemd service | Yes | Yes | ✅ Full |
| mlock support | Yes | Yes | ✅ Full |

### 6. Preflight Role
| Функция | Debian | RedHat | Статус |
| ------- | ------ | ------ | ------ |
| OS detection | Yes | Yes | ✅ Full |
| Version check | Ubuntu only | OracleLinux, AlmaLinux | ⚠️ Limited |
| Resource checks | Yes | Yes | ✅ Full |
| Port checks | Yes | Yes | ✅ Full |

**Текущие проверки:**
```yaml
preflight_debian_distributions:
  - Ubuntu  # Только Ubuntu!
preflight_ubuntu_versions:
  - "22.04"
  - "24.04"
preflight_redhat_distributions:
  - OracleLinux
  - AlmaLinux
  # Rocky Linux отсутствует!
  # RHEL отсутствует!
```

### 7. PKI Role
| Функция | Debian | RedHat | Статус |
| ------- | ------ | ------ | ------ |
| CA generation | Yes | Yes | ✅ Full |
| Host certs | Yes | Yes | ✅ Full |
| SANs (DNS+IP) | Yes | Yes | ✅ Full |
| community.crypto | Yes | Yes | ✅ Full |

### 8. Backup Role
| Функция | Debian | RedHat | Статус |
| ------- | ------ | ------ | ------ |
| Consul snapshots | Yes | Yes | ✅ Full |
| Nomad snapshots | Yes | Yes | ✅ Full |
| Vault snapshots | Yes | Yes | ✅ Full |
| Compression | Yes | Yes | ✅ Full |
| Retention | Yes | Yes | ✅ Full |

---

## ⚠️ Пробелы в поддержке

### CRITICAL Issues

#### 1. Docker для Nomad на Debian НЕ РЕАЛИЗОВАН
**Проблема**: Docker installation блок только для `ansible_facts.os_family == 'RedHat'`

**Влияние**: 
- На Debian/Ubuntu нельзя запустить Docker workloads в Nomad
- Нужно устанавливать Docker вручную

**Решение**:
```yaml
# Нужно добавить в roles/nomad/tasks/main.yml
- name: Install Docker dependencies (Debian-family)
  when:
    - nomad_install_docker | default(false)
    - ansible_facts.os_family == 'Debian'
  block:
    - name: Add Docker GPG key
      ansible.builtin.get_url:
        url: https://download.docker.com/linux/{{ ansible_facts.distribution | lower }}/gpg
        dest: /usr/share/keyrings/docker-archive-keyring.gpg
        mode: "0644"
      become: true

    - name: Add Docker repository
      ansible.builtin.apt_repository:
        repo: >-
          deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg]
          https://download.docker.com/linux/{{ ansible_facts.distribution | lower }}
          {{ ansible_facts.distribution_release }} stable
        state: present
      become: true

    - name: Install Docker packages
      ansible.builtin.apt:
        name:
          - docker-ce
          - docker-ce-cli
          - containerd.io
          - docker-compose-plugin
        state: present
        update_cache: true
      become: true

    - name: Enable and start Docker
      ansible.builtin.systemd:
        name: docker
        enabled: true
        state: started
      become: true
```

#### 2. CNI plugins для Nomad на Debian НЕ РЕАЛИЗОВАНЫ
**Проблема**: CNI plugins installation блок только для `ansible_facts.os_family == 'RedHat'`

**Влияние**: 
- Network isolation не работает на Debian/Ubuntu
- Bridge networking может не работать

**Решение**:
```yaml
# Нужно добавить в roles/nomad/tasks/main.yml
- name: Install CNI plugins (Debian-family)
  when:
    - nomad_install_cni | default(true)
    - ansible_facts.os_family == 'Debian'
  block:
    - name: Download CNI plugins
      ansible.builtin.get_url:
        url: "https://github.com/containernetworking/plugins/releases/download/v{{ nomad_cni_version }}/cni-plugins-linux-amd64-v{{ nomad_cni_version }}.tgz"
        dest: "/tmp/cni-plugins.tgz"
        mode: "0644"
      become: true

    - name: Ensure CNI bin directory exists
      ansible.builtin.file:
        path: "{{ nomad_cni_bin_dir }}"
        state: directory
        owner: root
        group: root
        mode: "0755"
      become: true

    - name: Extract CNI plugins
      ansible.builtin.unarchive:
        src: "/tmp/cni-plugins.tgz"
        dest: "{{ nomad_cni_bin_dir }}"
        remote_src: true
      become: true
```

### HIGH Priority Issues

#### 3. Preflight не проверяет Debian versions
**Проблема**: 
```yaml
preflight_debian_distributions:
  - Ubuntu  # Только Ubuntu!
```

**Влияние**: Debian 11/12 проходят без версионной проверки

**Решение**:
```yaml
preflight_debian_distributions:
  - Ubuntu
  - Debian
preflight_debian_versions:
  - "11"  # Bullseye
  - "12"  # Bookworm
```

#### 4. Preflight не проверяет Rocky Linux и RHEL
**Проблема**:
```yaml
preflight_redhat_distributions:
  - OracleLinux
  - AlmaLinux
  # Rocky Linux missing!
  # RedHat missing!
```

**Решение**:
```yaml
preflight_redhat_distributions:
  - OracleLinux
  - AlmaLinux
  - Rocky
  - RedHat
```

### MEDIUM Priority Issues

#### 5. Отсутствует SELinux support
**Проблема**: Нет конфигурации SELinux для RHEL систем

**Влияние**: На RHEL с enabled SELinux могут быть проблемы с permissions

**Решение**: Добавить SELinux contexts для:
- Consul data directory
- Nomad data directory
- Vault data directory
- TLS certificates

#### 6. Нет специфичных для Debian CNI defaults
**Проблема**: CNI переменные ориентированы на RHEL:
```yaml
nomad_cni_src_dir: /usr/libexec/cni  # RHEL path
nomad_cni_bin_dir: /opt/cni/bin
```

---

## 📈 Общая оценка поддержки

### Debian-based Systems: **8.0/10**
- ✅ Core functionality: 100%
- ✅ Package management: 100%
- ✅ Firewall (ufw): 100%
- ✅ HashiCorp services: 100%
- ⚠️ Docker for Nomad: 0%
- ⚠️ CNI plugins: 0%
- ⚠️ Preflight checks: 70%

### RedHat-based Systems: **9.0/10**
- ✅ Core functionality: 100%
- ✅ Package management: 100%
- ✅ Firewall (firewalld): 100%
- ✅ HashiCorp services: 100%
- ✅ Docker for Nomad: 100%
- ✅ CNI plugins: 100%
- ⚠️ Preflight checks: 80%
- ⚠️ SELinux: 0%

### Общая поддержка: **8.5/10**

---

## 🎯 Рекомендации

### Must Fix (для полной поддержки)
1. ✅ Добавить Docker installation для Debian/Ubuntu
2. ✅ Добавить CNI plugins installation для Debian/Ubuntu
3. ✅ Расширить preflight checks для Debian и Rocky/RHEL

### Should Fix
4. ⚠️ Добавить SELinux support для RHEL систем
5. ⚠️ Добавить AppArmor support для Ubuntu
6. ⚠️ Добавить platform-specific defaults (CNI paths, etc.)

### Nice to Have
7. 📝 Добавить тесты для всех поддерживаемых OS
8. 📝 Molecule tests для multi-OS
9. 📝 Документировать platform-specific quirks

---

## 🚀 Action Plan для полной поддержки

### Phase 1: Critical (Docker & CNI на Debian)
- [ ] Implement Docker installation for Debian/Ubuntu
- [ ] Implement CNI plugins for Debian/Ubuntu
- [ ] Add nomad_cni_version variable
- [ ] Test on Ubuntu 22.04/24.04

### Phase 2: Preflight improvements
- [ ] Add Debian version checking
- [ ] Add Rocky Linux to supported distros
- [ ] Add RHEL to supported distros
- [ ] Add version checks for Debian

### Phase 3: Security enhancements
- [ ] Implement SELinux contexts for RHEL
- [ ] Implement AppArmor profiles for Ubuntu
- [ ] Document security implications

### Phase 4: Testing & Documentation
- [ ] Add Molecule scenarios for all OS
- [ ] Document platform-specific features
- [ ] Create troubleshooting guide per OS

---

**Analyzed**: December 29, 2025  
**Status**: 85% cross-platform coverage  
**Action Required**: Docker & CNI for Debian (Critical)
