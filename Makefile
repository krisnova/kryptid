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

containerd_clone    =     git@github.com:kris-nova/containerd.git
runc_clone          =     git@github.com:kris-nova/runc.git
kubernetes_clone    =     git@github.com:kris-nova/kubernetes.git
make_flags          =     -j32

.PHONY: clone
clone: ## Clone containerd from Makefile flags
	@if [ ! -d containerd ]; then git clone $(containerd_clone); fi
	@if [ ! -d runc ]; then git clone $(runc_clone); fi
	@if [ ! -d kubernetes ]; then git clone $(kubernetes_clone); fi

logs: ## Run the logs
	journalctl -f -u containerd -u kubelet

restart: ## Restart systemd services
	systemctl daemon-reload
	systemctl restart containerd
	systemctl restart kubelet

all: containerd runc kubernetes ## Install containerd and runc from source!
	@cp -rv etc/* /etc

containerd: clone ## Install containerd from local source
	[ ! -d containerd ] && clone
	cd containerd && make $(make_flags)

runc: clone ## Install runc from local source

kubernetes: clone kubelet kubeadm ## Install kubernetes from local source

kubelet: clone ## Install kubelet from local source
	cd kubernetes && make kubelet $(make_flags)

kubeadm: clone ## Install kubernetes from local source
	cd kubernetes && make kubeadm $(make_flags)

install: install_containerd install_runc install_kubernetes ## Global install (all the artifacts)


install_runc: ## Install runc

install_kubernetes: ## Install kuberneretes
	cp -rv kubernetes/_output/bin/kubeadm /usr/local/bin/kubeadm
	cp -rv kubernetes/_output/bin/kubelet /usr/local/bin/kubelet


install_containerd: ## Install containerd
	cd containerd && make $(make_flags) install
	@cp -v containerd/containerd.service /lib/systemd/system/containerd.service

.PHONY: help
help:  ## 🤔 Show help messages for make targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}'