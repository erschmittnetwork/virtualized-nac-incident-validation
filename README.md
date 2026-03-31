# Virtualized NAC with Automated Wired 802.1X Incident Validation

## 1. Scope

This repository contains documentation sources and a publishing pipeline for a virtualized network access control (NAC) laboratory environment implementing wired IEEE 802.1X authentication, simulated incident reproduction, validation-first service remediation, and structured evidence preservation.

The environment is implemented as a proof-of-concept and is designed to reflect enterprise access-control and incident-response principles, including deterministic authentication flow, segmentation between authenticated and guest access domains, controlled failure simulation, targeted remediation, and evidentiary validation through service logs, packet captures, and ticketing artifacts.

Infrastructure provisioning artifacts and node configuration scripts are referenced by the documentation but are not included in this repository.

---

## 2. System Overview

The lab documents the design, implementation, and validation of a virtualized NAC environment composed of:

* A wired 802.1X supplicant using `wpa_supplicant`
* A wired 802.1X authenticator using `hostapd` in wired mode
* A FreeRADIUS AAA server validating EAP-MD5 credentials
* A pfSense-based guest isolation and policy enforcement segment
* A GLPI system used for asset and incident tracking
* A Splunk Universal Forwarder configured for local monitored inputs
* Python and Ansible automation supporting evidence summarization and service validation/remediation
* A CI/CD documentation pipeline producing deterministic HTML and PDF artifacts

The topology models a small enterprise access-control scenario in which an endpoint must authenticate over wired 802.1X before reaching protected services, while a separate guest segment remains internet-capable but isolated from internal lab networks.

The system is intended to support authentication validation, failure simulation, remediation testing, and post-incident evidence review under realistic SME-style operational constraints.

---

## 3. Architecture

### 3.1 Topology

The documented topology includes:

* A client endpoint acting as the wired 802.1X supplicant
* An access node acting as the wired 802.1X authenticator
* A routed path between the access node and the AAA/services segment
* A FreeRADIUS and observability node (`radius-splunk`)
* An operations/services node hosting GLPI
* A pfSense firewall/router supporting guest network segmentation
* A guest endpoint used for policy validation

The topology intentionally separates the authenticated access path from the guest path so that access-control and segmentation outcomes can be validated independently.

### 3.2 Authentication and Access Model

* **Supplicant Layer:** `wpa_supplicant` initiates wired IEEE 802.1X authentication using EAP-MD5.
* **Authenticator Layer:** `hostapd` in wired mode brokers EAPOL exchanges and relays authentication requests to the RADIUS server.
* **AAA Layer:** FreeRADIUS validates credentials and returns Access-Accept or Access-Reject outcomes.
* **Policy Outcome:** Successful authentication enables protected-path access; failed authentication leaves the client in an unauthorized state.

This separation allows the lab to observe client-side, authenticator-side, and backend AAA behavior as distinct but correlated evidence layers.

### 3.3 Incident Validation and Remediation Model

The incident workflow is based on:

* Deliberate authentication failure simulation
* Capture of client, authenticator, and RADIUS evidence during failure
* Structured ticketing and incident documentation in GLPI
* Validation-first automation using Ansible
* Optional service remediation through controlled restarts of:

  * `hostapd-wired.service`
  * `freeradius.service`
* Post-remediation re-test confirming successful authentication and authorization

Failure and recovery are validated using:

* `wpa_supplicant` debug output
* `hostapd` debug/service logs
* FreeRADIUS logs
* Packet captures on both the EAPOL-facing and RADIUS-facing segments
* GLPI incident artifacts
* Automation-generated validation outputs

### 3.4 Design Constraints

The lab intentionally omits features common in larger NAC deployments, including:

* Certificate-based EAP methods (for example, EAP-TLS)
* Centralized NAC policy engines
* Dynamic VLAN assignment
* Switch-enforced enterprise access control on physical hardware
* Production-grade SIEM search, alerting, or correlation
* High-availability RADIUS clustering

The objective is to model realistic SME-scale access-control and incident-response concepts while preserving architectural correctness and evidentiary rigor.

---

## 4. Repository Organization

```text
.
├── .github/workflows
│   └── deploy.yml
├── assets
│   ├── appendix-numbering-filter.lua
│   ├── doc.css
│   ├── header.html
│   └── screenshots
│       ├── pfSense_DHCP_Server_GUEST.png
│       ├── pfSense_Firewall_Rules_GUEST.png
│       ├── pfSense_Interfaces_Terminal.png
│       ├── GLPI_client-1_computer_asset.png
│       ├── GLPI-client-1_incident_ticket.png
│       ├── Wireshark_failed_8021x_ens38_pcap.png
│       ├── Wireshark_failed_8021x_ens39_pcap.png
│       ├── Wireshark_success_8021x_ens38_pcap.png
│       └── Wireshark_success_8021x_ens39_pcap.png
├── diagrams
│   └── reference-topology-diagram.mmd
├── docs
│   └── virtualized-nac-incident-validation.tex
└── README.md
```

### 4.1 Components

**.github/workflows/**
Defines the GitHub Actions workflow used to build and deploy documentation artifacts.

**assets/**
Contains CSS, a Lua script for appendix numbering, evidence screenshots, and a reusable HTML fragment injected into generated output.

**diagrams/**
Contains the Mermaid source file defining the logical and architectural topology diagram.

**docs/**
Contains the primary LaTeX documentation source from which artifacts are generated.

**README.md**
Provides an overview of the lab scope, architecture, and publishing workflow.

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
[https://erschmitt.com/docs/virtualized-nac-incident-validation.html](https://erschmitt.com/docs/virtualized-nac-incident-validation.html)

PDF
[https://erschmitt.com/docs/virtualized-nac-incident-validation.pdf](https://erschmitt.com/docs/virtualized-nac-incident-validation.pdf)

---

## 7. Exclusions

This repository excludes:

* Full VM build scripts
* Hypervisor-specific network adapter configuration exports
* Raw packet capture (`.pcap`) files
* Unredacted screenshots
* Live credentials, shared secrets, or authentication material
* Unredacted RADIUS or supplicant secrets
* Production-ready provisioning automation

Some of these elements are referenced by the documentation but intentionally excluded from source control.

---

## 8. Intended Use

This repository serves as:

* A reproducible technical reference for a virtualized NAC proof-of-concept lab
* A documentation artifact for wired 802.1X access-control design and validation
* A portfolio demonstration of incident simulation and remediation methodology
* An example of evidence-driven technical reporting
* An example of CI/CD-driven technical publishing

It is not intended to function as a prescriptive NAC deployment kit.

---

## 9. Evidence and Validation Model

The documented lab emphasizes multi-layer validation across several evidence domains:

* **Client-side evidence**

  * `wpa_supplicant` debug traces for failed and successful authentication attempts

* **Authenticator-side evidence**

  * `hostapd` service status, journal output, and curated debug captures

* **AAA-side evidence**

  * FreeRADIUS service logs and authorization behavior

* **Packet-level evidence**

  * Wireshark screenshots derived from captures on:

    * the client-facing EAPOL segment
    * the authenticator-to-RADIUS path

* **Operational evidence**

  * Ansible validation-only and remediation-enabled execution artifacts
  * Python parser summary output

* **Ticketing / workflow evidence**

  * GLPI incident record and associated asset/incident context

This layered approach is intended to demonstrate that incident conclusions are supported by correlated operational and protocol-level evidence rather than by single-source observation.

---

## 10. Versioning

The current documented version is **1.1.**

Version metadata is maintained within the LaTeX source and rendered outputs.
