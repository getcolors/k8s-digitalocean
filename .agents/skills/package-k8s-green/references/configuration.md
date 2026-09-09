# Configuration

`colors.yml` is a flat non-secret YAML map. The reference deployment is
`k8s-digitalocean/colors.yml`. Validation reports all errors together and fixes
the supported topology at one kubeadm control plane and one worker.

## Credentials

| Purpose | Environment variable |
|---|---|
| DigitalOcean compute and cloud controller | `COLORS_PAR_DO_TOKEN` |
| Cloudflare ExternalDNS | `COLORS_PAR_CLOUDFLARE_API_TOKEN` |
| R2 backend | `COLORS_PAR_R2_ACCESS_KEY_ID`, `COLORS_PAR_R2_SECRET_ACCESS_KEY` |
| S3 backend | `COLORS_PAR_S3_ACCESS_KEY_ID`, `COLORS_PAR_S3_SECRET_ACCESS_KEY` |

Never export `COLORS_PAR_PROFILE`. Keep `compute-prevent-destroy: true` in YAML.
The DigitalOcean token is streamed into the `digitalocean` Kubernetes Secret;
the Cloudflare token is streamed into `external-dns/cloudflare-api-token`.
Neither is rendered.

## Required desired state

- Providers: `provider-compute: digitalocean`, DNS `cloudflare` or `no-infra`,
  and backend `local`, `s3`, or `r2`.
- Exact versions: `kubernetes-version`, `flannel-version`, `flux-version`, and
  `digitalocean-cloud-controller-version` as `vMAJOR.MINOR.PATCH`.
- Kubernetes: kubeadm, Flannel, pod/service CIDRs, one control plane, one worker.
- GitOps: public HTTPS `repository`, branch, and `./`-relative path.
- DigitalOcean: name, region, both sizes, Ubuntu image, deployment-owned VPC
  CIDR, and administrative source CIDRs. `digitalocean-ssh-keys` is optional:
  leave it out and the deployment owns its keypair (`create` generates
  `~/.ssh/<profile>` and registers it under the profile's name; `delete`
  removes it last); supply an id or fingerprint already registered on the
  account to opt out. It replaced `digitalocean-ssh-key-fingerprint`, which is
  now refused by name.
- DNS/TLS: application host, Cloudflare zone, ExternalDNS owner ID, and ACME
  environment.

## Lifecycle and generated output

Create provisions the VPC, firewalls and Droplets; records the control-plane SSH
alias; installs containerd and exact kubeadm packages; initializes the cluster;
joins the worker; installs Flannel, DigitalOcean CCM and Flux; then verifies
GitOps, DNS, TLS, and HTTPS.

Remote state is `<profile>/k8s-infrastructure.tfstate`. `build` renders:

```text
.colors/<profile>/
├── k8s-infrastructure/  backend.tf.json main.tf
├── k8s-ansible-local/   ansible.cfg inventory.ini main.yml
├── k8s-ansible-remote/  ansible.cfg inventory.json create.yml delete.yml gitops.yml
└── k8s-acceptance/      acceptance.sh
```

Generated output can contain public/private node addresses but never tokens or
kubeconfig. Do not edit or commit it.

## Networking and recovery

The VPC admits all node-to-node traffic. Public SSH and TCP 6443 admit only the
configured CIDRs. Flannel binds the private `eth1` interface. DigitalOcean CCM
creates the public LoadBalancer requested by ingress-nginx; backend traffic
stays on the VPC.

A repeated `create` converges the existing cluster. For recovery after replacing
nodes, retain the remote OpenTofu state and rerun `create`. If Kubernetes is too
damaged to remove its LoadBalancer, do not destroy the VPC first: restore API
access or remove only the deployment-owned LoadBalancer explicitly, then rerun
the guarded delete.

## Compute dependency

colors-compute supplies the control-plane and worker machines, shared network,
firewalls, SSH keys, and remote R2 or S3 state. The package requests Kubernetes
controller support from the library and includes the returned tasks. A
compatible provider addition requires only a dependency update in this package.
Provider settings and capability validation belong to the library.

The default uses DigitalOcean with a deployment-owned VPC. Supply the selected
provider's settings and operator source CIDRs in `colors.yml`. Ansible uses the
returned node addresses and users. Generated keys live at `~/.ssh/<profile>`.
External SSH access requires an explicit `ssh-private-key-path` for Ansible.
The local SSH config leaves identity selection to the operator in external mode.

The previous combined infrastructure state requires explicit migration.
Updating the launcher does not transfer state or recreate the existing cluster.
