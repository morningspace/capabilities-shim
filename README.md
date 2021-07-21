# capabilities-shim

This repository is used to prove and demonstrate the feasibility of leveraging the combinition of OLM/ODLM and Crossplane along with its `Composition` to compose variant software capabilities.

For demo purpose, we defined below capabilities:
- Networking, including Kong as an API Gateway solution.
- Logging, including Elasticsearch and Kibana for logging storage and visualization.

You can follow the below documents to play the demo:
- [Prepare Environment](docs/prepare-env.md), to launch a kind cluster, install OLM and ODLM on it, then all necessary initialization needed before play with the demo.
- [Play with Capabilities](docs/play-with-capabilities.md), to launch the capabilities by applying corresponding custom resources.
