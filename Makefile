.PHONY: verify verify-publication

# Tool-light (jq only): manifest, routing, and backend-invariant plan.
# The full end-to-end (local + aws) runs in .gitea/workflows/ci.yaml.
verify:
	@docs/examples/verify.sh

# Post-publish receipt check; RECEIPT is exported by the CI flow.
verify-publication:
	@docs/examples/verify-publication.sh
