# Security policy

## Reporting a vulnerability

Report vulnerabilities privately, never in public issues, discussions or pull requests:

- GitHub private vulnerability reporting: https://github.com/act-security/terraform-azurerm-act/security/advisories/new (preferred)
- Email: security@act.security

Include the module version, the Terraform and provider versions, a configuration with every secret removed, and the impact you see.

## What to expect

- Acknowledgement within 3 business days.
- Triage within 10 business days.
- Coordinated disclosure: 90 days, or the fixed release if that comes first. We credit reporters unless they ask us not to.

## Supported versions

Before 1.0, only the latest release gets fixes. From 1.0, the latest minor of the current major.

## Scope

In scope: these modules, the Azure roles, role assignments, Event Hub access and diagnostic settings they create, and the GitHub workflows. A release that assigns a role to a principal other than `service_principal_id`, makes the custom role assignable outside the connected scope, or grants an action that `permissions/` does not list, is a vulnerability.

Out of scope: the Act platform itself (report it to security@act.security directly) and the Act provider (report it in its own repository).

## What the modules grant

Every permission ships inside the release, in `permissions/`, and the README lists them. The inputs are only the scope, Act's service principal and the onboarding values, never role content. The modules never create an app registration, a client secret or a Microsoft Graph grant. Compare `permissions_hash` across versions to see whether an upgrade changes what Act can read.
