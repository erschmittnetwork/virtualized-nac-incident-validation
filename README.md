# AWS WireGuard BGP WAN with Automated HA Hub Failover

## 1. Scope

This repository contains documentation sources and a publishing pipeline for an AWS-hosted hub-and-spoke WAN laboratory environment implementing encrypted overlay transport, dynamic routing, and automated high-availability hub failover.

The environment is implemented as a proof-of-concept and is designed to reflect enterprise WAN architectural principles, including deterministic routing behavior, separation of control and data planes, encrypted transport, automated failure handling, and operational observability under small-to-medium enterprise (SME) constraints.

Infrastructure provisioning artifacts and node configuration scripts are referenced by the documentation but are not included in this repository.

---

## 2. System Overview

The lab documents the design, implementation, and validation of a cloud-based WAN composed of:

* WireGuard tunnels providing encrypted overlay connectivity
* FRRouting (BGP) providing dynamic route exchange
* AWS-native automation mechanisms enabling active/standby hub failover
* A CI/CD pipeline producing deterministic documentation artifacts

The topology models a minimal WAN footprint consisting of two cloud-based hubs and multiple remote spokes. The design avoids proprietary SD-WAN platforms and instead relies on open protocols and cloud-native primitives.

The system is intended to support encrypted connectivity, dynamic route propagation, and automated hub role transition under failure conditions.

---

## 3. Architecture

### 3.1 Topology

The documented topology includes:

* Two AWS hub nodes operating in an active/standby role
* Multiple spoke nodes establishing overlay tunnels to the hubs
* WireGuard tunnels between hubs and spokes
* BGP peering sessions for control-plane route exchange
* Elastic IP reassignment for hub failover

### 3.2 Control and Data Planes

* **Control Plane:** BGP is used to distribute reachability information and enforce deterministic routing behavior.
* **Data Plane:** WireGuard tunnels provide encrypted transport independent of AWS-managed VPN services.

This separation allows routing logic and encrypted transport to be evaluated independently during failure and convergence testing.

### 3.3 Failover Model

The failover mechanism is based on:

* Hub role designation (active/standby)
* Automated reassignment of Elastic IP addresses
* BGP session re-establishment following hub transition

Failure scenarios are validated to observe routing convergence and tunnel reformation behavior.

### 3.4 Design Constraints

The lab intentionally omits features common in large-scale WAN deployments, including:

* VRF segmentation
* Active/active hub architectures
* Centralized SD-WAN controllers

The objective is to model realistic SME operational constraints while preserving architectural correctness.

---

## 4. Repository Organization

```
.
├── .github/workflows
│   └── deploy.yml
├── assets
│   ├── doc.css
│   └── header.html
├── diagrams
│   └── logical-architecture.mmd
├── docs
│   └── aws-wireguard-bgp-wan.tex
├── README.md
└── index.html
```

### 4.1 Components

**.github/workflows/**
Defines the GitHub Actions workflow used to build and deploy documentation artifacts.

**assets/**
Contains CSS and a reusable HTML fragment injected into generated output.

**diagrams/**
Contains the Mermaid source file defining the logical and architectural diagram.

**docs/**
Contains the primary LaTeX documentation source from which artifacts are generated.

**README.md**
Provides an overview of the lab scope and CI/CD pipeline for document delivery.

**index.html**
Defines the portfolio landing page for the published documentation.

---

## 5. Documentation Build Pipeline

### 5.1 Trigger Model

The pipeline executes on pushes to the `main` branch.

### 5.2 Build Process

The workflow performs the following operations:

1. Checkout repository state
2. Install Pandoc and LaTeX toolchain
3. Render Mermaid diagrams using containerized `mermaid-cli`
4. Copy static assets into the build directory
5. Generate HTML output using Pandoc
6. Generate PDF output using `pdflatex`
7. Assume an AWS IAM role using OIDC federation
8. Synchronize artifacts to Amazon S3
9. Invalidate CloudFront caches

### 5.3 Artifacts

Generated artifacts include:

* HTML documentation
* PDF documentation
* Rendered architecture diagrams
* Static site assets

### 5.4 Deployment

Artifacts are deployed to:

* Amazon S3 for static hosting
* CloudFront for content distribution and cache control

Authentication uses GitHub OIDC with an AWS IAM role and does not rely on static credentials.

---

## 6. Published Outputs

HTML
[https://erschmitt.com/docs/aws-wireguard-bgp-wan.html](https://erschmitt.com/docs/aws-wireguard-bgp-wan.html)

PDF
[https://erschmitt.com/docs/aws-wireguard-bgp-wan.pdf](https://erschmitt.com/docs/aws-wireguard-bgp-wan.pdf)

---

## 7. Exclusions

This repository does not include:

* Infrastructure-as-code templates
* Instance configuration files
* Automation scripts used for provisioning

These elements are referenced by the documentation but intentionally excluded from source control.

---

## 8. Intended Use

This repository serves as:

* A reproducible technical reference
* A documentation artifact for WAN architecture design
* A portfolio demonstration of network engineering methodology
* An example of CI/CD-driven technical publishing

It is not intended to function as a production deployment kit.

---

## 9. Versioning

The current documented version is **1.3**.

Version metadata is maintained within the LaTeX source and rendered outputs.
