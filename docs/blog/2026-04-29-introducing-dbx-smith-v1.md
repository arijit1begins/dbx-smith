---
slug: introducing-dbx-smith-v1
title: Introducing DbxSmith - The Forge for Isolated Developer Environments
authors: [arijit1begins]
tags: [launch, v1.0, distrobox, security]
image: /img/dbx-smith-v1-hero.png
---

![DbxSmith v1.0 Launch Hero](/img/dbx-smith-v1-hero.png)


Today, we are officially launching **DbxSmith**, a professional-grade provisioning suite for **Distrobox** and **Podman**. 

DbxSmith was born out of a simple need: making containerized developer environments more secure, reproducible, and easy to manage without the overhead of complex orchestration. Whether you need a simple host-mirrored environment or a strictly isolated airgapped vault, DbxSmith is your forge.

### Why DbxSmith?

Standard containers are powerful, but managing multiple environments with different configurations, network rules, and shell integrations can be difficult. DbxSmith automates this complexity using **Modular Manifests** and **Provisioning Strategies**.

### Key Features of v1.0.0:
- **Modular Provisioning**: Define your environment once, deploy it anywhere.
- **Airgapped Strategy**: Sever network bridges for high-security "Vault" environments.
- **Automated Lifecycle**: Seamless installation, updates, and atomic teardowns to keep your host clean.
- **Interactive Documentation**: A full documentation suite (where you are reading this!) to guide you through every feature.

{/* truncate */}

### Getting Started

You can install DbxSmith with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/arijit1begins/dbx-smith/main/install.sh | bash
```

Check out our [Documentation](/docs/intro) for deep dives into strategies and architecture. We are excited to see what you build!

---
*Stay tuned for more updates, and don't forget to check out our [GitHub repository](https://github.com/arijit1begins/dbx-smith)!*
