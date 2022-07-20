# kyrptid

---

Please help me become an independent programmer by donating directly to my `ko-fi` site below.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/D1D8CXLHZ) 

---

An opinionated Kubernetes distribution specifically for Arch linux.

### bin

In here you will find many useful bash scripts for setting up kube.

```
# Used to bootstrap a new cluster
./bin/karch-init

# Used to provision CNI in a new cluster
./bin/karch-cni
```

### make

Here is the bulk of my work. Use the Makefile to build the Kubernetes components and start the systemd services.

```
make
sudo -E make install
sudo -E make enable start
```

### Cilium CLI

Suggest using Cilium CNI

```
make cilium-cli
sudo -E make install_cilium_cli
./bin/kryptid-cni-cilium
```
