# vmware-setup.md

In this file I am preparing my system for building a full Active Directory and Linux security lab using VMware Workstation. Before I install Windows Server and Rocky Linux inside VMware, I need to be sure my host system and VMware itself are properly set up. I also need to understand what a hypervisor is, how VMware uses virtualization, and why hardware requirements matter in practice.

Resource Download Links:
- [VMWare WorkStation](https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion)
- [Windows Server 2022 ISO](https://www.microsoft.com/en-us/evalcenter/download-windows-server-2022)
- [Rocky Linux ISO](https://rockylinux.org/download)

---

- [vmware-setup.md](#vmware-setupmd)
  - [Understanding What VMware Workstation Is](#understanding-what-vmware-workstation-is)
  - [Why I Need VMware for This Lab](#why-i-need-vmware-for-this-lab)
  - [Host System Requirements and Why They Matter](#host-system-requirements-and-why-they-matter)
    - [CPU requirements](#cpu-requirements)
    - [Memory (RAM) requirements](#memory-ram-requirements)
    - [Storage considerations](#storage-considerations)
    - [Virtualization support in BIOS or UEFI](#virtualization-support-in-bios-or-uefi)
  - [Installing VMware Workstation](#installing-vmware-workstation)
  - [Preparing Storage for Virtual Machines](#preparing-storage-for-virtual-machines)
  - [Understanding VMware Virtual Disks](#understanding-vmware-virtual-disks)
  - [Understanding Virtual CPUs and Memory](#understanding-virtual-cpus-and-memory)
  - [First Launch of VMware](#first-launch-of-vmware)
  - [What I Achieve After This File](#what-i-achieve-after-this-file)

<br>
<br>

## Understanding What VMware Workstation Is

- <mark><b>VMware Workstation</b></mark> is an application that enables virtualization on a desktop or laptop. <mark><b>Virtualization</b></mark> means running multiple operating systems at the same time on a single physical machine by creating virtual computers. These virtual computers are known as <mark><b>virtual machines</b></mark>. Each virtual machine behaves like a separate physical server even though it shares the hardware resources of my host system.

- VMware itself is called a hypervisor. A <mark><b>hypervisor</b></mark> is a software layer that manages and allocates physical resources such as CPU cores, memory, storage space, and network interfaces to each virtual machine. VMware Workstation is often called <mark><b>a Type-2 hypervisor</b></mark> because it runs on top of a regular operating system like Windows or Linux. A Type-1 hypervisor would run directly on bare metal without a host OS, but that is not what I am using here.

- Inside VMware I can create a virtual environment with multiple servers, each acting as if it were on its own physical hardware. This is exactly what I will use to build <mark><b>a domain controller</b></mark>, a Linux server that joins the domain, and later various security configurations. The advantage is that I am not risking my real system and I can rebuild or revert easily.

<br>
<details>
<summary><b>Type-1 Hypervisor (bare-metal)</b></summary>
<br>

A Type-1 hypervisor <mark><b>runs directly on the hardware</b></mark>. There’s no operating system in between.
Because of that, it’s faster, more secure, and used in data centers.

Examples I’d see in real enterprise environments:
- VMware ESXi
- Microsoft Hyper-V
- KVM

I basically treat the server itself as the hypervisor.

</details>

<br>
<details>
<summary><b>Type-2 Hypervisor (hosted)</b></summary>
<br>

A Type-2 hypervisor <mark><b>runs on top of a normal operating system</b></mark>.
So first I install Windows or Linux, and then I install the hypervisor as a software application.

Examples I use in labs:
- VMware Workstation
- VirtualBox
This is great for learning, but not ideal for enterprise production performance.

</details>
<br>

---

<br>
<br>

## Why I Need VMware for This Lab

- The goal of my learning path is to build an actual Active Directory domain, configure Linux authentication against it, and learn Linux security and hardening techniques in a realistic environment. Doing this directly on my real machine is not practical or safe. VMware gives me an isolated environment that behaves like a real network.

- I can do the following safely inside VMware:
  - Install Windows Server 2022 as a domain controller
  - Install Rocky Linux as a domain member
  - Configure DNS, DHCP, AD DS, Kerberos, and PAM without damaging my real OS
  - Break configurations on purpose and learn how to fix them
  - Use snapshots to quickly roll back changes

- Creating this kind of environment without virtualization would require multiple physical machines, switching equipment, and network configuration on actual hardware. Virtualization makes it easy and cost-effective.

---

<br>
<br>

## Host System Requirements and Why They Matter

- Before installing VMware or creating virtual machines, I need to make sure my host computer has enough resources. The host system is the physical laptop or desktop that will run VMware Workstation.

- I must consider several resource categories because each virtual machine uses part of the host's resources.

### CPU requirements
- Modern multi-core processors are required because each VM needs at least one or two CPU cores. If the CPU is too weak, running multiple servers will become very slow. The hypervisor schedules CPU time between the virtual machines, and inadequate resources cause noticeable lag.

### Memory (RAM) requirements
- Windows Server 2022 alone can require several gigabytes of RAM. Rocky Linux will need less, but still a few gigabytes. If my host has only 8 GB total, the system will quickly start swapping memory to disk and become slow. A realistic starting point is at least 16 GB on the host, because I plan to run both VMs at the same time, and possibly others later.

### Storage considerations
- I need enough disk space for the VMware installation and for each virtual machine. A Windows Server virtual disk might be 60 GB or more. Rocky Linux might be 30 GB or more. Snapshots also consume additional disk space. It is common to underestimate storage, so planning ahead saves time.

### Virtualization support in BIOS or UEFI
- Most modern CPUs include virtualization extensions such as Intel VT-x or AMD-V. VMware uses these extensions to run 64-bit operating systems efficiently. If virtualization is disabled in BIOS or UEFI, VMware will still install, but performance and compatibility will be affected. I need to check and enable this setting before I begin.

---

<br>
<br>

## Installing VMware Workstation

- To install VMware Workstation, I download the installer from the official VMware website. There are two main editions: VMware Workstation Pro and VMware Workstation Player. The Player edition is free for personal use, but the Pro edition offers more features. For my learning lab, VMware Workstation Pro gives me the best environment, especially when I start doing more advanced networking and snapshots.

- When installing, I usually accept the default options. The installer places the VMware components, creates helper services, and sets up virtual networking drivers. After installation, I should reboot the host computer so the virtualization services initialize properly.

---

<br>
<br>

## Preparing Storage for Virtual Machines

- VMware will create virtual machine files, and these files can become large over time. Before I start creating VMs, I decide where these files should be stored. I can store them on a fast SSD for better performance rather than a slow HDD. The location should have enough free space because Windows Server and snapshots alone can grow significantly during the lab.

- It is useful to have a dedicated folder such as "VMs" on a large drive. Keeping everything in one place makes it easier to back up or migrate later. This also prevents cluttering my system drive.

---

<br>
<br>

## Understanding VMware Virtual Disks

- When I create a virtual machine, VMware asks for a disk size. The disk inside the virtual machine is not a physical disk but a file known as <mark><b>a virtual disk</b></mark>. VMware uses the <mark><b>.vmdk</b></mark> format for these files. From within the VM, the operating system sees it as a standard hard disk.

- I can choose <mark><b>thin provisioning</b></mark> so that the virtual disk file grows only as data is written. <mark><b>Thick provisioning</b></mark> allocates the full size immediately, which uses more space but may offer slightly better performance. For learning and testing, thin provisioning is practical.

---

<br>
<br>

## Understanding Virtual CPUs and Memory

- VMware allows me to assign virtual CPUs and virtual memory to each VM. Assigning more resources improves performance, but I must avoid oversubscribing my host system. If I assign too much RAM to VMs, the host OS itself will starve and everything will become slow.

- As a general idea, Windows Server usually performs well with at least two virtual CPU cores and around six to eight gigabytes of RAM. Rocky Linux is lighter, and two to four gigabytes will often be enough for domain integration and security practice. I will adjust resources later based on performance.

---

<br>
<br>

## First Launch of VMware

- After installation, I start VMware Workstation and review the interface. The key areas are the virtual machine library on the left, the main workspace, and the menus for creating new VMs. I also verify that the virtualization engine shows no warnings. If VMware reports that virtualization is disabled, I need to correct that in BIOS or UEFI before continuing.

- At this stage I do not create a VM yet. First I make sure VMware is functioning properly, the host has virtualization enabled, and I have enough storage space. Then I can begin creating the Windows Server and Rocky Linux virtual machines separately in their own detailed setup files.

---

<br>
<br>

## What I Achieve After This File

- After completing the setup described here, my system is ready to host virtual machines. I understand what virtualization is, why VMware Workstation is necessary for this project, and what resources my system must provide. I also know why proper hardware requirements and virtualization support matter for stable and realistic lab environments.

- The next file will focus on installing Windows Server 2022 as a virtual machine and preparing it for domain controller promotion.