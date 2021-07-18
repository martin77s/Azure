<div align="center">
  <h1 align="center">Awesome SAP on Azure</h1>
  <p align="center">A curated list of awesome <a href="https://azure.microsoft.com/en-us/solutions/sap/">SAP on Azure</a> resources, blogs, tools, examples and more.</p>

  <p align="center">
      <a href="https://github.com/sindresorhus/awesome">
        <img alt="awesome list badge" src="https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg">
      </a>
      <a href="http://makeapullrequest.com">
        <img alt="pull requests welcome badge" src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat">
      </a>
  </p>
</div>

### Contents

- [Resources](#resources)
    - [Getting Started](#getting-started)
    - [High Availability](#high-availability)
    - [Disaster Recovery](#disaster-recovery)
    - [Backup](#backup)
    - [SAP Shared Files NFS](#sap-shared-files-nfs)
    - [SSO](#sso)
    - [Infrastructure as Code and Automation](#infrastructure-as-code-and-automation)
    - [Security](#security)
    - [Monitoring](#monitoring)
    - [Books](#books)

#### Getting Started

- [Docs](https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/sap/get-started) - Start here with SAP on Azure documentation.
- [Checklist](https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/sap/sap-deployment-checklist) - SAP on Azure deployment checklist from the official docs.

#### High Availability

- [SAP NetWeaver on Azure HA Architecture](https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/sap/sap-high-availability-architecture-scenarios) - High-availability architecture and scenarios for SAP NetWeaver.
- [SAP HANA on Azure High Availability](https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/sap/sap-hana-availability-overview) - SAP HANA high availability for Azure virtual machines.

#### Disaster Recovery

- [SAP HANA DR on Azure](https://azure.microsoft.com/en-us/blog/disaster-recovery-for-sap-hana-systems-on-azure/) - Disaster recovery for SAP HANA Systems on Azure.
- [SAP NetWeaver DR on Azure](https://docs.microsoft.com/en-us/azure/site-recovery/site-recovery-sap) - Set up disaster recovery for a multi-tier SAP NetWeaver app deployment.
- [Protect SAP with ASR](https://docs.microsoft.com/en-us/azure/site-recovery/site-recovery-sap) - Your SAP on Azure – Part 7 – Protect SAP landscape with Azure Site Recovery.

#### Backup

- [HANA Backup on Azure](https://docs.microsoft.com/en-us/azure/backup/backup-azure-sap-hana-database) - Back up SAP HANA databases in Azure VMs.
- [VM BAckup on Azure](https://docs.microsoft.com/en-us/azure/backup/backup-azure-vms-introduction) - An overview of Azure VM backup.

#### SAP Shared Files NFS

- [NFS solution options for SAP shared files](https://techcommunity.microsoft.com/t5/running-sap-applications-on-the/deploy-sap-ascs-ers-with-azure-files-nfs-v4-1-shares/ba-p/2038320) - Deploy SAP ASCS/ERS with Azure Files NFS v4.1 shares.

#### SSO

- [Principal Propagation for SAP oData Services](https://github.com/ROBROICH/Teams-Chatbot-SAP-NW-Principal-Propagation) - Hands-on Lab chatbot example for Principal propagation between Azure and SAP Netweaver OData services.
- [Principal Propagation for SAP BTP](https://github.com/ROBROICH/Teams-Chatbot-SAP-NW-Principal-Propagation) - Principal propagation in a multi-cloud solution between Microsoft Azure and SAP Business Technology Platform (BTP), Part I: Building the foundation.
- [OAuth 2.0 configuration in SAP](https://medium.com/@ThomasWecker/oauth-2-0-configuration-in-sap-4333e92a1d65) - OAuth 2.0 configuration in SAP.
- [SSO for ABAP Engine with oAuth](https://blogs.sap.com/2019/10/17/single-sign-on-for-abap-engine-with-azure-active-directory-using-oauth/) - Single sign on for ABAP Engine with Azure active directory using OAuth. 
- [SSO API calls with Postman](https://github.com/azuredevcollege/SAP/blob/master/sap-oauth-saml-flow/PostmanSetup/README.md) - Postman setup for SSO API calls.  
- [SAP Netweaver SSO with AAD](https://docs.microsoft.com/en-us/azure/active-directory/saas-apps/sap-netweaver-tutorial) - Azure Active Directory Single sign-on (SSO) integration with SAP NetWeaver.
- [SAP HANA SSO with AAD](https://docs.microsoft.com/en-us/azure/active-directory/saas-apps/saphana-tutorial) - Azure Active Directory integration with SAP HANA.

#### Infrastructure as Code and Automation
- [Github Repo](https://github.com/Azure/sap-hana) - SAP on Azure deployment automation repository on Github.
- [Github Repo](https://github.com/microsoft/SAPAzureSnooze) - SAP Snooze PowerApp.
- [SAP on Azure SLES15 Automation](https://www.linkedin.com/pulse/sap-azure-automation-sles-15-alexander-tuerk/) - SAP on Azure: Automation to SLES 15.
- [SAP Hana on Azure Platform as a Service](https://www.linkedin.com/pulse/sap-hana-azure-platform-service-nandkishor-gaikwad/) - SAP Hana on Azure Platform as a Service. 
- [SAP Golden Image Management](https://www.linkedin.com/pulse/saphanaonazure-value-stream-1-golden-image-part-19-gaikwad/) - SAP on Azure Golden Image Management.
- [SAP Infrastructure Provisioning and Instalation](https://www.linkedin.com/pulse/saphanaonazure-value-stream-2-infrastructure-sap-part-gaikwad/) - SAP on Azure Infrastructure Provision and SAP Installation.

#### Security
- [Security Design](https://azure.microsoft.com/en-us/blog/sap-on-azure-architecture-designing-for-security/) - SAP on Azure Architecture - Designing for security.
- [Security Operations](https://blogs.sap.com/2019/07/21/sap-security-operations-on-azure/) - SAP Security Operations on Azure. 
- [Continuous Threat Monitoring](https://docs.microsoft.com/en-us/azure/sentinel/sap-deploy-solution) - Deploy SAP continuous threat monitoring (public preview). 

#### Monitoring
- [SAP NetWeaver Monitoring](https://techcommunity.microsoft.com/t5/running-sap-applications-on-the/sap-netweaver-monitoring-azure-monitoring-for-sap-solutions/ba-p/2262721) - SAP NetWeaver monitoring- Azure Monitoring for SAP Solutions.
- [SAP Monitoring Solution](https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/sap/azure-monitor-overview) - Azure Monitor for SAP Solutions (preview).
- [SAP Telemetry](https://www.microsoft.com/en-us/itshowcase/end-to-end-telemetry-for-sap-on-azure) - Telemetry and monitoring with SAP on Azure.

#### Books
- [Implementation Guide](https://azure.microsoft.com/en-us/resources/sap-on-azure-implementation-guide/) - SAP on Azure Implementation Guide.
- [Architecture and Administration](https://www.sap-press.com/sap-on-microsoft-azure_5174/) - SAP on Azure Architecture and Administration. 
