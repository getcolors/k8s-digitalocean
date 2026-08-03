# k8s-digitalocean

Live desired state for a compact kubeadm Kubernetes cluster on DigitalOcean.

- One `s-2vcpu-4gb` control plane and one worker in `ams3`
- Flannel networking and DigitalOcean cloud-controller integration
- Flux source: [`getcolors/k8s-helloworld`](https://github.com/getcolors/k8s-helloworld)
- Public app: <https://hello.bigconfig.online>
- Package: [`getcolors/k8s`](https://github.com/getcolors/k8s)

```sh
./green build
./green create --dry-run
./green create
./green kubectl get nodes
./green kubectl get pods -A
```

Credentials live only in ignored `.envrc.private`. Never set
`COLORS_PAR_PROFILE`, never edit `.colors/`, and retain
`compute-prevent-destroy: true`.

Flux installs ingress-nginx, cert-manager, and ExternalDNS. DigitalOcean CCM
creates the ingress LoadBalancer, ExternalDNS maintains
`hello.bigconfig.online`, and cert-manager obtains the Let's Encrypt
certificate through HTTP-01.
