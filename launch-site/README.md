# ApplyReady Vets launch-site draft

This folder is the local, publication-ready structure for the minimum company and App Store support site. It is not
approved legal advice and must not be published while any page displays `DRAFT — NOT FOR PUBLICATION` or contains a
`[FINAL ...]` placeholder.

## Pages

- `index.html` — product, pricing, independence, and company landing page.
- `support.html` — support contact, troubleshooting, purchase/restore, Files, and deletion guidance.
- `privacy.html` — privacy-policy draft matched to version 0.7.0 build 18 and the currently disabled public service.
- `terms.html` — terms-of-use starter draft.
- `sources.html` — dated official-source and non-affiliation references.

## Before publication

1. Approve the final app name and legal entity after professional clearance.
2. Buy and connect the final domain using the founder's account.
3. Create a monitored domain email such as `support@final-domain.com`.
4. Have qualified legal/privacy counsel review every page against the final binary and operating company.
5. Replace every `[FINAL ...]` value and remove every draft banner.
6. Run `./scripts/validate-launch-site.command --release`.
7. Publish only after Jonathan explicitly approves the destination, final text, and account action.
8. Put the live HTTPS support and privacy URLs into `ios/project.yml`, then run `make app-store-preflight`.

Draft validation can be run before the final information exists:

```zsh
./scripts/validate-launch-site.command --draft
```

