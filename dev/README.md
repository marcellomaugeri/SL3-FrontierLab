# The dev folder

This folder starts the components of SL3-FrontierLab on your own computer, for development, when a Proxmox server is out of reach.
It holds a second Terraform configuration, which asks a Kubernetes cluster for the machines that the root of the repository asks Proxmox for.
Each machine receives the setup file of its component exactly as the full deployment does, so a change to a component can be tried here first.

The folder serves development alone.
The [system security plan](../oscal/system-security-plan.yaml) describes the deployment on Proxmox, and the firewall of each machine belongs to that deployment.
The folder also awaits its first run on a cluster: its files follow the documentation of Terraform, KubeVirt and CDI, and a first run may call for adjustments.

## How it works

Kubernetes runs containers, and the components are machines.
[KubeVirt](https://kubevirt.io/) therefore joins the cluster as an add-on that runs virtual machines, together with [CDI](https://github.com/kubevirt/containerized-data-importer), its companion that turns a disk image into a disk.
The recipe in [`modules/virtual-machine/`](modules/virtual-machine/) then asks for one machine with a system disk from Debian's image, a blank data disk, and the setup file as its Cloud-Init data.
The data disk carries the serial `drive-scsi1`, so that the machine finds it under the name that the setup file expects.

A machine has the processor type of the computer that runs the cluster.
For this reason, the setting `TF_VAR_architecture` selects the image of Debian and the build of SeaweedFS that match your processor.
When the cluster lacks hardware virtualisation, as a local cluster on a Mac does, KubeVirt runs the machine through software emulation, which is slower.

## What you need

- Docker and [kind](https://kind.sigs.k8s.io/), which starts a cluster inside Docker.
- `kubectl` and [`virtctl`](https://kubevirt.io/user-guide/user_workloads/virtctl_client_tool/), the command of KubeVirt that reaches a machine.
- Terraform 1.17 or later.
- The key pair of the deployment, `~/.ssh/sl3_lab`, which the main [README](../README.md#install-proxmox-ve-on-a-vps) creates.

## Prepare a cluster

First, create a cluster:

```bash
kind create cluster --name sl3-frontierlab
```

Then install KubeVirt, as its [installation guide](https://kubevirt.io/user-guide/cluster_admin/installation/) describes:

```bash
export RELEASE=v1.9.1
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-operator.yaml
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-cr.yaml
kubectl -n kubevirt wait kv kubevirt --for condition=Available
```

On a cluster that lacks hardware virtualisation, switch KubeVirt to software emulation: run `kubectl edit -n kubevirt kubevirt kubevirt` and add the following lines under `spec`:

```yaml
configuration:
  developerConfiguration:
    useEmulation: true
```

Finally, install CDI, as its [README](https://github.com/kubevirt/containerized-data-importer) describes:

```bash
export VERSION=v1.66.1
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-operator.yaml
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-cr.yaml
```

## Settings

The settings live in `.env`, which git ignores.
Copy the template and fill in each empty value:

```bash
cp .env.example .env
```

| Entry | Meaning |
|---|---|
| `TF_VAR_kube_context` | The cluster to use, as `kubectl` names it; kind names it `kind-sl3-frontierlab`. |
| `TF_VAR_architecture` | The processor of your computer: `amd64` for Intel and AMD processors, `arm64` for Apple and other Arm processors. |
| `TF_VAR_assets` | The components to deploy, by folder name, for example `["weight-storage"]`. |
| `TF_VAR_ssh_public_key` | The public key that opens the machines, the content of `~/.ssh/sl3_lab.pub`. |

## Deploy

Load the settings and let Terraform create the machine:

```bash
set -a; . ./.env; set +a
terraform init
terraform apply
```

The first start takes some time, because CDI downloads the image of Debian before the machine sets itself up.
When the run ends, Terraform prints `weight_enclave_address = "vm/weight-enclave/sl3-frontierlab"`, and `virtctl` opens a shell on the machine:

```bash
virtctl ssh -i ~/.ssh/sl3_lab debian@vm/weight-enclave/sl3-frontierlab
```

On the machine, the commands of the [Deploy](../README.md#deploy) section of the main README confirm that the setup has finished and that the weights sit on the data disk.
Finally, `terraform destroy` removes the machine, and `kind delete cluster --name sl3-frontierlab` removes the cluster.
