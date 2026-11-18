# Subscription

Creates Act's custom role in one subscription and assigns it, with the built-in roles, to Act's service principal. Set the variables to the onboarding values Act issues for the subscription, apply, then register the deployment with Act.

An Entra administrator must have approved Act's app in the tenant first; the `tenant` submodule checks that and outputs `service_principal_id`. The identity that applies needs Owner or User Access Administrator on the subscription.
