# =========================================================================== #
#            MIT License Copyright (c) 2022 Kris Nóva <kris@nivenly.com>      #
#                                                                             #
#                 ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓                 #
#                 ┃   ███╗   ██╗ ██████╗ ██╗   ██╗ █████╗   ┃                 #
#                 ┃   ████╗  ██║██╔═████╗██║   ██║██╔══██╗  ┃                 #
#                 ┃   ██╔██╗ ██║██║██╔██║██║   ██║███████║  ┃                 #
#                 ┃   ██║╚██╗██║████╔╝██║╚██╗ ██╔╝██╔══██║  ┃                 #
#                 ┃   ██║ ╚████║╚██████╔╝ ╚████╔╝ ██║  ██║  ┃                 #
#                 ┃   ╚═╝  ╚═══╝ ╚═════╝   ╚═══╝  ╚═╝  ╚═╝  ┃                 #
#                 ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛                 #
#                                                                             #
#                        This machine kills fascists.                         #
#                                                                             #
# =========================================================================== #

default: help

# Generic config
kubernetes_version  =     v1.24.0
kubernetes_clone    =     git@github.com:kubernetes/kubernetes.git
containerd_version  =     v1.6.4
containerd_clone    =     git@github.com:containerd/containerd.git
runc_version        =     v1.1.2
runc_clone          =     git@github.com:opencontainers/runc.git
critools_version    =     v1.24.1
critools_clone      =     git@github.com:kubernetes-sigs/cri-tools.git
nerdctl_version     =     v0.20.0
nerdctl_clone       =     git@github.com:containerd/nerdctl.git
helm_version        =     v3.9.0
helm_clone          =	  git@github.com:helm/helm.git
crio_version        =     v1.22.4
crio_clone          =     git@github.com:cri-o/cri-o.git
make_flags          =     -j32

# Arch linux specific
mirror              =     https://mirror.chaoticum.net/arch
ebtables_tarball    =     ebtables.tar.gz
ebtables_download   =     https://aur.archlinux.org/cgit/aur.git/snapshot/$(ebtables_tarball)
conntrack_zst       =     conntrack-tools-1.4.6-2-x86_64.pkg.tar.zst
conntrack_download  =     $(mirror)/extra/os/x86_64/$(conntrack_zst)
cniplugins_zst      =	  cni-plugins-1.1.1-2-x86_64.pkg.tar.zst
cniplugins_download =     $(mirror)/community/os/x86_64/$(cniplugins_zst)
conmon_zst          =     conmon-1:2.1.0-1-x86_64.pkg.tar.zst
conmon_download     =     $(mirror)/community/os/x86_64/$(conmon_zst)

all: containerd runc kubernetes nerdctl critools ## Install containerd and runc from source!

.PHONY: bin
bin: ## Add the bin scripts to $PATH
	@cp -rv bin/* /usr/bin

crio: clone ## Install crio
	cd cri-o && make $(make_flags)

containerd: clone ## Install containerd from local source
	cd containerd && make $(make_flags)

runc: clone ## Install runc from local source
	cd runc && make $(make_flags)

kubernetes: clone kubelet kubeadm kubectl ## Install kubernetes from local source

kubelet: clone ## Install kubelet from local source
	cd kubernetes && make $(make_flags) kubelet

kubeadm: clone cri-tools ## Install kubernetes from local source
	cd kubernetes && make $(make_flags) kubeadm

kubectl: clone
	cd kubernetes && make $(make_flags) kubectl

helm: clone ## Install helm
	cd helm && make $(make_flags)

nerdctl: clone ## Install nerdctl (nerdctl is docker drop-in for containerd)
	cd nerdctl && make $(make_flags)

critools: clone ## Install critools (crictl is required for kubeadm)
	cd cri-tools && make $(make_flags)

archlinux: ebtables_aur conntrack_aur cniplugins_aur conmon_aur ## Arch linux specific dependencies. Good luck everyone else.

ebtables_aur: ## Install arch linux ebtables
	mkdir -p ebtables
	wget $(ebtables_download) && tar -xzf $(ebtables_tarball)
	cd ebtables && makepkg -si

conntrack_aur: ## Install arch linux ebtables
	wget $(conntrack_download)
	pacman -U $(conntrack_zst)

cniplugins_aur: ## Install arch linux ebtables
	wget $(cniplugins_download)
	pacman -U $(cniplugins_zst)

conmon_aur: ## Install arch linux conmon
	wget $(conmon_download)
	pacman -U $(conmon_zst)

install: bin install_containerd install_runc install_kubernetes install_nerdctl install_critools install_helm install_crio ## Global install (all the artifacts)
	@cp -rv etc/* /etc

clone: ## Clone containerd from Makefile flags
	@if [ ! -d containerd ]; then git clone $(containerd_clone); cd containerd && git checkout tags/$(containerd_version) -b $(containerd_version); fi
	@if [ ! -d cri-o ]; then git clone $(crio_clone); cd crio && git checkout tags/$(crio_version) -b $(crio_version); fi
	@if [ ! -d runc ]; then git clone $(runc_clone); cd runc && git checkout tags/$(runc_version) -b $(runc_version); fi
	@if [ ! -d helm ]; then git clone $(helm_clone); cd helm && git checkout tags/$(helm_version) -b $(helm_version); fi
	@if [ ! -d nerdctl ]; then git clone $(nerdctl_clone); cd nerdctl && git checkout tags/$(nerdctl_version) -b $(nerdctl_version); fi
	@if [ ! -d kubernetes ]; then git clone $(kubernetes_clone); cd kubernetes && git checkout tags/$(kubernetes_version) -b $(kubernetes_version); fi
	@if [ ! -d cri-tools ]; then git clone $(critools_clone); cd cri-tools && git checkout tags/$(critools_version) -b $(critools_version); fi

logs: ## Run the logs
	journalctl -f -u crio -u kubelet

kubelet-errors: ## Run the kubelet logs
	journalctl -fu kubelet | grep --color -A 1 -B 7 "Error: "

enable: ## Enable systemd services
	systemctl daemon-reload
	systemctl enable kubelet
	#systemctl enable containerd
	systemctl enable crio

restart: ## Restart systemd services
	systemctl daemon-reload
	#systemctl restart containerd
	systemctl restart crio
	systemctl restart kubelet

start: ## Start systemd services
	systemctl daemon-reload
	#systemctl start containerd
	systemctl start crio
	systemctl start kubelet

stop: ## Stop systemd services
	systemctl daemon-reload
	#systemctl stop containerd
	systemctl stop crio
	systemctl stop kubelet

install_crio: ## Install crio
	cd cri-o && make $(make_flags) install

install_nerdctl: ## Install nerdctl
	cd nerdctl && make $(make_flags) install

install_runc: ## Install runc
	cp -rv runc/runc /usr/bin

install_critools: ## Install critools
	cd cri-tools && make $(make_flags) install

install_helm: ## Install helm
	cd helm && make $(make_flags) install

install_kubernetes: ## Install kuberneretes
	cp -rv kubernetes/_output/bin/* /usr/bin

install_containerd: ## Install containerd
	cd containerd && make $(make_flags) install
	@cp -v containerd/containerd.service ./etc/systemd/system/containerd.service

clean:
	@echo "This will DESTROY local copies of source code!"
	read -p "Press any key to continue..."
	rm -rvf kubernetes*
	rm -rvf containerd*
	rm -rvf nerdctl*
	rm -rvf conntrack*
	rm -rvf helm*
	rm -rvf cri-o*
	rm -rvf runc*
	rm -rvf cri-tools*
	rm -rvf ebtables*
	rm -rvf *.tar.*

.PHONY: help
help:  ## 🤔 Show help messages for make targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}'
