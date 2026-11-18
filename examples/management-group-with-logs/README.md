# Management group with logs

Connects a management group with every permission group Act offers:

1. `tenant` checks that an Entra administrator approved Act's app and finds its service principal. Until then, the plan fails and prints the consent link.
2. The root module creates Act's custom role at the management group and assigns it, with AKS RBAC Reader, to that service principal.
3. `activity-logs` creates Act's Event Hub namespace in `events_subscription_id` and streams the activity log of every subscription under the management group to it.
4. `entra-logs` streams the tenant's Entra ID audit and sign-in logs to the same namespace.

The identity that applies needs Owner or User Access Administrator on the management group and the events subscription, read access to service principals in Microsoft Graph, and the Security Administrator or Global Administrator role in Entra ID for the Entra ID diagnostic setting.
