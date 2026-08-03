# CLAUDE.md

## What this repository is

Desired state for `k8s-digitalocean`: one kubeadm control plane and one worker
in a deployment-owned DigitalOcean VPC, with Flannel, DigitalOcean CCM, Flux,
and the public `getcolors/k8s-helloworld` application at
`https://hello.bigconfig.online`.

`colors.yml` is source. `.colors/` is generated and must never be read as source,
edited, or committed. `.envrc.private` contains credentials and is ignored by
the default-deny `.gitignore`.

The root `green` is a copy of
`.agents/skills/package-k8s-green/green`. After `npx skills update -p -y`, copy
the payload again or the project keeps running the old launcher.

## Commands

```sh
./green build
./green create --dry-run
./green create
./green kubectl get nodes
./green kubectl get pods -A
```

Build and dry-run require no credentials. A real delete first removes the
Kubernetes-managed DigitalOcean Load Balancer, then destroys only this
project's VPC, firewalls, and Droplets. It remains protected by
`compute-prevent-destroy: true`; lift the guard only for an authorized run with
`COLORS_PAR_COMPUTE_PREVENT_DESTROY=false`.

## Credentials and safety

Credentials are `COLORS_PAR_*` exports in `.envrc.private`. Never export
`COLORS_PAR_PROFILE`. DigitalOcean and Cloudflare tokens are streamed into
Kubernetes Secrets and never rendered. Remote state is
`k8s-digitalocean/k8s-infrastructure.tfstate` in the shared R2 bucket.

SSH and TCP 6443 admit only the operator CIDR in `colors.yml`. `./green kubectl`
uses the root-owned admin kubeconfig over SSH; no kubeconfig is copied locally.
Flux owns ingress-nginx, cert-manager, ExternalDNS, and the application. The
Package Skill owns cluster infrastructure and bootstrap.

## Verification and recovery

```sh
./green kubectl get nodes
./green kubectl -n flux-system get gitrepository,kustomization
./green kubectl get helmrelease -A
./green kubectl -n hello-world get deployment,pods,ingress,certificate
curl --fail https://hello.bigconfig.online/healthz
```

Repeated `create` converges an intact cluster. If API recovery is required,
restore SSH/API access before deletion so Kubernetes can remove its LoadBalancer
finalizer; never destroy the VPC while that deployment-owned load balancer
remains.

## Git

Do not commit or push unless explicitly authorized.
