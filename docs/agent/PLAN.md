# Development plan
- [ ] Inventory repository and reconcile actual infra with scope; record file paths and blockers.
- [ ] Define OpenAPI contract and service-specific migrations.
- [ ] Implement organization service and tests.
- [ ] Implement notice service, audit, Redis and attachment adapter; tests.
- [ ] Implement React static UI and E2E tests.
- [ ] Compose integration and container builds.
- [ ] Prepare EKS manifests and release/rollback guide; validate offline.
- [ ] Implement CVE collectors, SQLite schema, SBOM and risk gate; offline tests.
- [ ] Prepare test-only security CI, signature/attestation and admission policies.
- [ ] Implement local kind Cilium/Hubble/Tetragon lab and policies.
- [ ] Implement runtime correlation and observability dashboards.
- [ ] Final review, exact test evidence and PR. Stop.
AWS live validation: deferred until human restores infrastructure. No auto-deploy. If usage limit reached, record next task and stop.