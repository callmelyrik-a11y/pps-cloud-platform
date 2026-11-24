# Development plan
- [ ] Inventory repository and reconcile actual infra with scope; record file paths and blockers.
- [ ] Define OpenAPI contract and service-specific migrations.
- [ ] Implement organization service and tests.
- [ ] Implement notice service, audit, Redis and attachment adapter; tests.
- [ ] Implement React static UI and E2E tests.
- [ ] Compose integration and container builds.
- [ ] Prepare EKS manifests and release/rollback guide; validate offline.
- [ ] Final review, exact test evidence and PR. Stop.
AWS live validation: deferred until human restores infrastructure. No auto-deploy. If usage limit reached, record next task and stop.