# SL3-FrontierLab

SL3-FrontierLab is a small infrastructure for the weights of AI models, which anyone can deploy on a single Proxmox server.
It implements security controls from RAND's Security Level 3 (SL3), a set of 262 controls that protect the confidentiality of model weights.
Each control that it implements points to the configuration that implements it, so that a reader can check the claim, reuse the configuration or challenge the choice.
At present it holds one machine, the Weight enclave, which implements part of one control, SC-4.

## Background

The weights of an AI model are the values that training produces, and a copy of the weights is, in effect, a copy of the model.
For this reason, RAND's report [*Achieving AI Model Weight Security Level 3 (SL3)*](https://www.rand.org/pubs/research_reports/RRA4704-1.html) sets out 262 security controls that protect the confidentiality of model weights against organised cybercrime and insider threats.
These controls adapt [NIST SP 800-53 revision 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final), the catalogue of security and privacy controls of the United States National Institute of Standards and Technology (NIST), and each one carries a text written for model weights.
Control SC-4, for example, asks that the storage of model weights sits on dedicated volumes, separated from general-purpose data.

A set of controls becomes useful once a system states which control it implements, with what, and where.
[OSCAL](https://pages.nist.gov/OSCAL/), NIST's Open Security Controls Assessment Language, offers file formats for this purpose, and this repository uses two of them.
The first is the [profile](https://pages.nist.gov/OSCAL/learn/concepts/layer/control/profile/), which selects controls from a catalogue and adjusts their text; here it selects RAND's 262 controls and gives each one RAND's wording.
The second is the [system security plan](https://pages.nist.gov/OSCAL/learn/concepts/layer/implementation/ssp/), which describes a system, its components and the way in which each component implements a control.

The infrastructure is likewise described in files.
[Terraform](https://developer.hashicorp.com/terraform) reads a description of machines and networks and then creates them, and [Proxmox VE](https://www.proxmox.com/en/products/proxmox-virtual-environment/overview) is the virtualisation platform on which those machines run.
Each machine sets itself up at its first start through [Cloud-Init](https://cloudinit.readthedocs.io/en/latest/), and the storage machine runs [SeaweedFS](https://github.com/seaweedfs/seaweedfs), an object store that offers the S3 interface of Amazon's Simple Storage Service.

## Scope

The repository stands for the infrastructure of a frontier AI provider at a small scale.
Accordingly, virtual machines on one Proxmox server take the place of the provider's machines, and the storage is sized for a few small open-weight models.
The table below lists the controls implemented so far, and the [system security plan](oscal/system-security-plan.yaml) holds the full record.

| Control | What holds today | Component | Status |
|---|---|---|---|
| SC-4, Information in Shared System Resources | Model weights sit on a disk of their own, in a machine of its own. | Weight enclave | Partial: two of the control's five sentences |

The remaining sentences of SC-4 concern the clearing of memory and the isolation between tenants.
They belong to the inference and training machines, which later steps add.
The deployment itself assumes a Proxmox server, so a laptop lies outside the scope.

## Design

The repository keeps two things apart: the configuration, which creates the infrastructure, and the record, which states which controls that infrastructure implements.
The following subsections describe each of them, then follow one control from its text to the configuration, and finally give the main choices with their reasons.

### The deployment

The Terraform files at the root of the repository describe the whole deployment.
To begin with, [`main.tf`](main.tf) downloads the operating system image, creates a private network for the machines, and calls a recipe once for each component that the operator lists.
The recipe, in [`modules/virtual-machine/`](modules/virtual-machine/), creates one virtual machine with a system disk, a separate data disk and a firewall, so that every machine is built in the same way.
What makes each machine particular is its setup, which lives in the component's own folder; for the Weight enclave, this is [`weight-storage/cloud-init.yaml.tftpl`](weight-storage/cloud-init.yaml.tftpl).
Lastly, the values of one deployment, such as the server's address and the list of components, come from a file named `.env`, which stays on the operator's computer.

The Weight enclave shows how these parts work together.
Terraform creates a machine with two disks and hands it the setup file.
At its first start, the machine prepares the data disk, mounts it at `/srv/seaweedfs`, installs SeaweedFS and starts it under an account of its own.
From then on, SeaweedFS keeps every stored object on the data disk, and its service starts only while that disk is mounted.

### The record

The record consists of two OSCAL documents in [`oscal/`](oscal/).
The profile, `sl3_profile.json`, holds the 262 controls with RAND's text, and the script in [`utils/build_profile/`](utils/build_profile/) builds it from [RAND's public repository](https://github.com/RANDCorporation/achieving-ai-model-weight-sl3), so that anyone can reproduce it.
The system security plan, `system-security-plan.yaml`, describes the system and its components, and it holds one entry for each implemented control.
Each entry names the components that implement the control, quotes the sentences that they implement, explains how each sentence holds, states how far the control is implemented, and links to the files that do the work.
As a result, the answer to the question of which controls are implemented, and how, lies in this one file.

### One control, from its text to the configuration

SC-4 illustrates the path from a control to the configuration.
RAND's text for SC-4 has five sentences, and the Weight enclave implements two of them.

The first sentence reads: "Assign model weight storage to dedicated volumes or filesystems logically or physically separated from general-purpose data."
To meet it, the recipe gives the machine a second disk in [`modules/virtual-machine/main.tf`](modules/virtual-machine/main.tf), and the setup file mounts that disk at `/srv/seaweedfs`, where SeaweedFS keeps the weights.

The second sentence reads: "For frontier or high-sensitivity models, prefer dedicated infrastructure over shared compute where operationally feasible."
To meet it, the module call `weight_storage` in [`main.tf`](main.tf) gives the Weight enclave a machine of its own, on which the setup file installs a single application, SeaweedFS.

The entry for SC-4 in the system security plan records exactly this: it quotes both sentences, links to the three files, and carries the status `partial`, since the other three sentences await later machines.
A reader can therefore start from the control, follow its entry, and arrive at the configuration; [Deploy](#deploy) then shows how to confirm the result on the running machine.

### Main choices

Several choices shape the repository, and each of them rests on a reason.
First, the conventions come from official documentation: the names of the Terraform files and the place of the recipe follow [HashiCorp's style guide](https://developer.hashicorp.com/terraform/language/style), so that a reader who knows Terraform finds each block where they expect it.
Second, a single recipe builds every machine, which keeps the machines alike and leaves each component's folder to describe what is particular to it.
Third, the machines share a private network that follows the [source NAT example](https://pve.proxmox.com/pve-docs/chapter-pvesdn.html#pvesdn_setup_example_nat) of Proxmox's documentation: they reach the internet through the server in order to download their software, and their addresses stay inside the server.
Each machine also receives a fixed address in that network, so that the configuration and the firewall rules can name it.
Fourth, the firewall of each machine admits SSH from the server and drops every other incoming connection, since the operator's session through the server is the one connection that the machine needs at this stage.
Fifth, the software is pinned: the download of the Debian 13 image is checked against its published checksum, and the setup file does the same for the SeaweedFS release, so that every operator installs the same files.
In the same cautious spirit, SeaweedFS answers on the machine alone at this stage, and access from other machines will arrive together with access control.
Finally, Terraform reaches the server's management interface through an SSH tunnel, because SSH already identifies the server by its host key and encrypts the traffic.
One caveat deserves mention: the provider marks the resource that applies network changes, `proxmox_sdn_applier`, as experimental.

## Repository layout

```
.
├── README.md                       this guide
├── LICENSE                         the licence of the repository
├── .gitignore                      keeps the state, saved plans and .env out of git
├── .env.example                    the template of the operator's settings
├── .terraform.lock.hcl             the provider's checksums, written by Terraform
├── terraform.tf                    the versions of Terraform and of the Proxmox provider
├── providers.tf                    the provider's connection to the server
├── variables.tf                    the operator's settings
├── locals.tf                       the addresses derived from the range of the network
├── main.tf                         the image, the network and one call of the recipe per component
├── outputs.tf                      the address of the deployed machine
├── modules/
│   └── virtual-machine/            the recipe for one machine: its disks, its setup and its firewall
├── weight-storage/
│   └── cloud-init.yaml.tftpl       the setup of the Weight enclave
├── oscal/
│   ├── sl3_profile.json            the 262 controls with RAND's text
│   └── system-security-plan.yaml   the record of the implemented controls
├── docs/
│   └── CONTRIBUTING.md             how to add a control or a component
└── utils/
    └── build_profile/              the script that builds the profile from RAND's repository
```

## Getting started

Deploying the infrastructure takes three steps: preparing a Proxmox server, filling in the settings, and running Terraform.
The operator's computer needs [Terraform](https://developer.hashicorp.com/terraform/install) 1.17 or later, an SSH client with an agent, and a POSIX shell.

### Install Proxmox VE on a VPS

The server runs Proxmox VE 9 and offers hardware virtualisation; on a virtual server, `grep -E -c 'vmx|svm' /proc/cpuinfo` prints a number above zero and `/dev/kvm` exists.
The Weight enclave takes 2 processor cores, 4 GB of memory and 84 GB of disk.
Proxmox's guide [Install Proxmox VE on Debian 13 Trixie](https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_13_Trixie) covers the installation itself, and its step "Create a Linux Bridge" can be left out, since Terraform creates the network of this deployment.

The deployment uses a key pair of its own, which opens both the provider's account on the server and the machines.
Create it on your computer and load it into your SSH agent:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/sl3_lab -C sl3-frontierlab
ssh-add ~/.ssh/sl3_lab
```

The steps below then add what the deployment relies on, and they run on the server as root.

1. **Load the network files.**
   Proxmox writes the network of this deployment into `/etc/network/interfaces.d/`, so `/etc/network/interfaces` has to end with the line that loads that folder.

   ```bash
   grep -q '^source /etc/network/interfaces.d/\*' /etc/network/interfaces || echo 'source /etc/network/interfaces.d/*' >> /etc/network/interfaces
   ```

2. **Name DNS servers that the machines can reach.**
   New machines take the server's DNS settings, so `/etc/resolv.conf` has to list real DNS servers.
   On the tested VPS the file was a link to a local resolver at `127.0.0.53`, an address that points each machine at itself, and a plain file took its place.

   ```bash
   rm /etc/resolv.conf
   printf 'nameserver %s\n' <dns-server> > /etc/resolv.conf
   ```

3. **Let the storage hold what the deployment needs.**
   The storage `local` holds the disks of the machines, their Cloud-Init files and the imported image, so it needs the content types `images`, `snippets` and `import` beside its defaults.

   ```bash
   pvesm set local --content iso,vztmpl,backup,images,snippets,import
   ```

4. **Create an API token for Terraform.**
   The commands follow the section "Creating an API Token on the Proxmox Server" of the [provider's documentation](https://registry.terraform.io/providers/bpg/proxmox/latest/docs), whose example role they reuse.
   The provider presents that role as an example that grants more than most deployments need, so narrowing it is worthwhile.
   The last command prints the token's secret once, and the secret belongs in `.env`.

   ```bash
   pveum user add terraform@pve
   pveum role add Terraform -privs "Realm.AllocateUser, VM.PowerMgmt, VM.GuestAgent.Unrestricted, Sys.Console, Sys.Audit, Sys.AccessNetwork, VM.Config.Cloudinit, VM.Replicate, Pool.Allocate, SDN.Audit, Realm.Allocate, SDN.Use, Mapping.Modify, VM.Config.Memory, VM.GuestAgent.FileSystemMgmt, VM.Allocate, SDN.Allocate, VM.Console, VM.Clone, VM.Backup, Datastore.AllocateTemplate, VM.Snapshot, VM.Config.Network, Sys.Incoming, Sys.Modify, VM.Snapshot.Rollback, VM.Config.Disk, Datastore.Allocate, VM.Config.CPU, VM.Config.CDROM, Group.Allocate, Datastore.Audit, VM.Migrate, VM.GuestAgent.FileWrite, Mapping.Use, Datastore.AllocateSpace, Sys.Syslog, VM.Config.Options, Pool.Audit, User.Modify, VM.Config.HWType, VM.Audit, Sys.PowerMgmt, VM.GuestAgent.Audit, Mapping.Audit, VM.GuestAgent.FileRead, Permissions.Modify"
   pveum aclmod / -user terraform@pve -role Terraform
   pveum user token add terraform@pve provider --privsep=0
   ```

5. **Create an SSH user for the provider.**
   The provider uploads the Cloud-Init files over SSH, as a user whose two `sudo` rules come from the section "SSH User" of the same documentation.
   The last line installs the public key of the deployment, the content of `~/.ssh/sl3_lab.pub`.

   ```bash
   useradd -m -s /bin/bash terraform
   printf '%s\n' 'terraform ALL=(root) NOPASSWD: /usr/sbin/pvesm apiinfo' 'terraform ALL=(root) NOPASSWD: /usr/bin/tee ^/var/lib/vz/snippets/[a-zA-Z0-9_][a-zA-Z0-9_.-]*$' | tee /etc/sudoers.d/terraform.pending >/dev/null
   visudo -cf /etc/sudoers.d/terraform.pending
   mv /etc/sudoers.d/terraform.pending /etc/sudoers.d/terraform
   chmod 0440 /etc/sudoers.d/terraform
   install -d -m 700 -o terraform -g terraform /home/terraform/.ssh
   printf '%s\n' '<public-key>' | install -m 600 -o terraform -g terraform /dev/stdin /home/terraform/.ssh/authorized_keys
   ```

   From your computer, the documentation's own test then prints `APIVER` followed by a number:

   ```bash
   ssh -i ~/.ssh/sl3_lab terraform@<server-address> sudo pvesm apiinfo
   ```

6. **Forward the traffic of the machines.**
   The machines reach the internet through the server, which therefore has to forward IPv4 packets, as in the [masquerading example](https://pve.proxmox.com/pve-docs/chapter-sysadmin.html#sysadmin_network_masquerading) of Proxmox's guide.

   ```bash
   printf '%s\n' 'net.ipv4.ip_forward = 1' | tee /etc/sysctl.d/99-sl3-frontierlab.conf
   sysctl -p /etc/sysctl.d/99-sl3-frontierlab.conf
   ```

7. **Switch on the datacenter firewall.**
   The firewall rules of each machine take effect once Proxmox's datacenter firewall is on.
   Before switching it on, add your own address to the `management` IP set, which keeps SSH and the web interface open to you, as [Proxmox's firewall documentation](https://pve.proxmox.com/pve-docs/chapter-pve-firewall.html#_enabling_the_firewall) explains.
   On the tested VPS this step was still pending, so it rests on Proxmox's documentation alone.

### Settings

The settings of one deployment live in `.env`, which git ignores.
Copy the template and fill in each empty value:

```bash
cp .env.example .env
```

| Entry | Meaning |
|---|---|
| `TF_VAR_proxmox_ip` | The server's public IP address, which the provider uses for SSH. |
| `TF_VAR_node_name` | The name that Proxmox shows for the server. |
| `PROXMOX_VE_API_TOKEN` | The token of step 4, written as `terraform@pve!provider=<secret>` in single quotes. |
| `PROXMOX_VE_SSH_USERNAME` | The SSH user of step 5, `terraform`. |
| `PROXMOX_VE_SSH_AGENT` | `true`, so that the provider signs in through your SSH agent and the private key stays out of the file. |
| `PROXMOX_VE_ENDPOINT` | `https://127.0.0.1:8006/`, the local end of the SSH tunnel. |
| `PROXMOX_VE_INSECURE` | `true` through the tunnel, where SSH identifies the server and Proxmox presents a certificate that it signed itself. |
| `TF_VAR_assets` | The components to deploy, by folder name, for example `["weight-storage"]`. |
| `TF_VAR_ssh_public_key` | The public key that opens the machines, the content of `~/.ssh/sl3_lab.pub`. |
| `TF_VAR_lab_subnet` | Optional: the range of the private network, to change when the server already uses `172.16.0.0/24`. |

An operator whose server holds a certificate from a public authority can set the server's address as the endpoint and `PROXMOX_VE_INSECURE` to `false`.

### Deploy

First, open the tunnel in a second terminal and leave it open:

```bash
ssh -N -L 8006:127.0.0.1:8006 <user>@<server-address>
```

Then load the settings and let Terraform prepare its working folder:

```bash
set -a; . ./.env; set +a
terraform init
```

Next, ask Terraform for its plan, read it, and apply it:

```bash
terraform plan -out=lab.tfplan
terraform apply lab.tfplan
```

The plan deserves a careful reading, because a component whose name is missing from `TF_VAR_assets`, for instance through a spelling mistake, is planned for removal together with its data disk.
Terraform applies a saved plan once, so `lab.tfplan` can be deleted afterwards.
When the run ends, Terraform prints `weight_enclave_address = "172.16.0.2"`, and the machine is reachable through the server:

```bash
ssh -J <user>@<server-address> -i ~/.ssh/sl3_lab debian@172.16.0.2
```

On the machine, the following commands confirm that the setup has finished and that the weights sit on the data disk, as the first implemented sentence of SC-4 asks:

| Command | Expected result |
|---|---|
| `cloud-init status --wait` | `status: done` |
| `findmnt -n -o SOURCE,TARGET,FSTYPE /srv/seaweedfs` | the first partition of the data disk, `/srv/seaweedfs` and `ext4` |
| `systemctl is-active seaweedfs` | `active` |
| `sudo ls /srv/seaweedfs` | the volume files of SeaweedFS, which end in `.dat` and `.idx` |

Finally, `terraform destroy` removes the machine, the network and the image from the server.

*Note:* This was tested on a VPS with Debian 13.

## Contributing

Contributions are welcome, and each of them follows the same path: a change to the configuration, a check on the deployed machine, and an entry in the system security plan.
The [contribution guide](docs/CONTRIBUTING.md) explains this path step by step, for a new control as well as for a new component.
A decision of the repository can likewise be challenged through an issue that cites the control and the source in question.

## Acknowledgements

This work is developed as part of the [Frontier AI Security Residency](https://www.securefrontier.ai/), a residency programme run by [ERA](https://erafellowship.org/).
