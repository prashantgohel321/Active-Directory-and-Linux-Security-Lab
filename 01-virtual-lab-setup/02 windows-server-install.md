# windows-server-install.md

In this file I am installing <mark><b>Windows Server 2022 as a virtual machine</b></mark> inside VMware Workstation. The purpose of this installation is to prepare <mark><b>a future Domain Controller</b></mark> for Active Directory. I will not promote it to a Domain Controller in this file, because that is a separate and important step. Here I only focus on the installation itself, understanding what I am installing, why I choose certain options, and how the installation process actually works.

---

- [windows-server-install.md](#windows-server-installmd)
  - [Understanding What Windows Server 2022 Is](#understanding-what-windows-server-2022-is)
  - [Choosing the Edition](#choosing-the-edition)
  - [VM Hardware Configuration in VMware](#vm-hardware-configuration-in-vmware)
    - [Firmware selection (BIOS or UEFI)](#firmware-selection-bios-or-uefi)
    - [Storage controller and disk type](#storage-controller-and-disk-type)
    - [Memory allocation](#memory-allocation)
    - [CPU configuration](#cpu-configuration)
    - [Network type selection](#network-type-selection)
    - [Virtual disk size](#virtual-disk-size)
  - [Starting the Installation in VMware](#starting-the-installation-in-vmware)
  - [Custom Installation and Disk Layout](#custom-installation-and-disk-layout)
  - [Creating the Administrator Password](#creating-the-administrator-password)
  - [Understanding the Administrator Account](#understanding-the-administrator-account)
  - [Installing VMware Tools](#installing-vmware-tools)
  - [Windows Updates](#windows-updates)
  - [Network Settings After Installation](#network-settings-after-installation)
  - [Preparing for Domain Controller Promotion](#preparing-for-domain-controller-promotion)
  - [What I Achieve After This File](#what-i-achieve-after-this-file)


<br>
<br>

## Understanding What Windows Server 2022 Is

- <mark><b>Windows Server 2022</b></mark> is Microsoft’s enterprise server operating system. It is designed to run services that manage <u><b>identities</b></u>, <u><b>authentication</b></u>, <u><b>authorisation</b></u>, <u><b>DNS</b></u>, <u><b>file services</b></u>, <u><b>group policies</b></u>, and many more enterprise roles. Unlike a normal Windows desktop operating system, the server edition is built to be a central authority in a network rather than a personal workstation.

- In this lab, Windows Server 2022 will eventually host <mark><b>Active Directory Domain Services</b></mark>. That means this system will become the root of authentication for my entire test network. Every Linux and Windows machine in my environment will trust this server for identity and authentication. Because of this, installation should be clean, predictable, and stable.

<br>
<details>
<summary><b>Q. AD DS (Active Directory Domain Services)</b></summary>
<br>

- AD DS is the part of Active Directory that actually <mark><b>stores and manages identities</b></mark>. It keeps the <mark><b>database</b></mark> of <u><b>users</b></u>, <u><b>computers</b></u>, <u><b>groups</b></u>, and security <u><b>policies</b></u>.

- When I join a system to the domain, AD DS becomes the <mark><b>central place</b></mark> that decides <u><b>who I am</b></u>, <u><b>what I’m allowed to access</b></u>, and <u><b>what rules apply to me</b></u>.

- So basically, AD DS is the<mark><b> brain of identity and authentication</b></mark> in an enterprise Windows domain.

</details>
<br>

---

<br>
<br>

## Choosing the Edition

- During installation I will be asked to choose between different server editions, typically <mark><b>Standard</b></mark> or <mark><b>Datacenter</b></mark>, and <mark><b>with</b></mark> or <mark><b>without Desktop</b></mark> Experience. For a learning lab, <mark><b>choosing Standard Edition with Desktop Experience</b></mark> makes sense. The Desktop Experience includes a full graphical interface, which makes it easier to explore menus, tools, and Server Manager without relying entirely on PowerShell from day one.

- A Server Core installation offers better security and lower resource usage, but it requires more command‑line knowledge and is not ideal for a beginner environment. Since my goal is to learn concepts deeply, I start with Desktop Experience and later I can experiment with Server Core.

---

<br>
<br>

## VM Hardware Configuration in VMware

- When I create the Windows Server virtual machine in VMware Workstation, VMware guides me through several configuration screens. These steps define how the virtual hardware behaves and what capabilities the VM will have. Understanding these options is important because they directly affect networking, boot method, compatibility, and performance.

![alt text](<../Diagrams/01_02_01 VM HW Config.png>)

### Firmware selection (BIOS or UEFI)
- During the VM creation wizard I choose between legacy BIOS and UEFI firmware. Before deciding, I need to understand what firmware actually is. Firmware is a low-level program stored on the motherboard that initializes the hardware when a machine powers on. It performs basic checks, sets up hardware, and then hands control to the operating system boot loader.

<br>
<details>
<summary><b>Q. What is BIOS?</b></summary>
<br>

- BIOS stands for <mark><b>Basic Input/Output System</b></mark>. It is an older firmware standard that has existed since early PCs. BIOS initializes the hardware in a very traditional way and uses the Master Boot Record (MBR) method to locate and start the operating system. MBR has limitations, such as supporting disks only up to a certain size and having limited partition structure.

</details>
<br>

<details>
<summary><b>Q. What is UEFI?</b></summary>
<br>

- UEFI stands for <mark><b>Unified Extensible Firmware Interface</b></mark>. It is the modern replacement for BIOS. UEFI understands newer hardware standards, has more advanced initialization routines, and uses GPT (GUID Partition Table) instead of MBR. GPT supports larger disks and more partitions. UEFI can provide faster boot times and better security features.

</details>
<br>

<details>
<summary><b>Q. How they differ in working?</b></summary>
<br>

- BIOS reads the first sector of the disk (the master boot record) to find the boot loader, while UEFI can load boot information directly from special partitions known as EFI System Partitions. UEFI can work with modern hardware security features while BIOS remains tied to older approaches.

</details>
<br>

<details>
<summary><b>Q. Which should I choose</b></summary>
<br>

- For Windows Server 2022, choosing UEFI is recommended because it matches modern hardware requirements, supports secure boot techniques, and avoids legacy boot limitations. BIOS is present mainly for compatibility with very old operating systems. In this lab, I select UEFI.

</details>
<br>

### Storage controller and disk type
- VMware presents options for virtual disk setup. I choose a virtual disk in VMDK format. When asked whether to split or create a single file, I can choose either, but split files sometimes make moving the VM easier. <mark><b>Thin provisioning</b></mark> means VMware does not allocate the full size immediately. This saves storage and grows only as needed.

- In VMware, the <mark><b>virtual disk</b></mark> is stored as a VMDK file. That file is basically the hard drive of the virtual machine. Everything the VM installs or stores ends up inside that VMDK. When VMware asks whether to split the disk or keep it in one file, it’s just asking how I want that virtual hard drive stored on my real machine.

- If I choose thin provisioning, VMware won’t grab the entire disk space right away—it will grow the VMDK file only when the VM actually uses the space. That way I don’t waste disk space on my host.

### Memory allocation
- The wizard shows a slider or fields where I allocate RAM. I set six to eight gigabytes because Windows Server and later domain services need memory for proper performance. If I set too little RAM, installation and role configuration will be slow.

### CPU configuration
- I choose at least two virtual CPUs. The wizard often suggests reasonable defaults. Active Directory and DNS benefit from additional CPU resources, and the system will feel more responsive.

### Network type selection
- VMware displays several choices for networking:

  - <mark><b>Bridged networking</b></mark>: The VM becomes part of the same physical network as the host. It receives an IP from the same router that my physical system uses.
  - <mark><b>NAT networking</b></mark>: The VM uses a virtual NAT and receives an IP belonging to a virtual network inside VMware. It still has internet access through the host but remains isolated from the physical LAN.
  - <mark><b>Host-only networking</b></mark>: The VM communicates only with the host and other host-only VMs. No external network access.

For this lab I select NAT because it keeps the environment isolated while allowing communication between VMs and internet access for updates. NAT also reduces the risk of interfering with my actual home or office network.

### Virtual disk size
- I set at least sixty gigabytes. Windows Server requires significant space for system files, roles, updates, and logs. Thin provisioning helps conserve host storage and I do not need to commit the full size at once.

- After choosing these options, the VM creation wizard finishes and the virtual machine is ready to power on and begin installation.


<br>
<br>

Before starting the installation, I configure the virtual hardware of the VM. This includes CPU allocation, memory size, virtual disk type, and network adapter mode. These settings affect performance, stability, and later Active Directory deployment.

## Starting the Installation in VMware

- Once VMware Workstation is running, I create a new virtual machine. I select the Windows Server 2022 ISO as the installation source. VMware will boot from this ISO and show the Windows setup screen.

- I first select language, time, and keyboard preferences. This does not affect Active Directory functions directly, but it determines how the system displays information. I continue to "Install now".

---

<br>
<br>

## Custom Installation and Disk Layout

- When asked to choose the installation type, I select Custom installation. This allows Windows to install on the virtual disk I created earlier.

- The installer shows the virtual disk as unallocated space. I simply select this disk and continue. Windows automatically creates required partitions such as the system partition and recovery partition. I do not need to manage them manually for this lab. The installation then copies files and reboots when finished.

---

<br>
<br>

## Creating the Administrator Password

- The installer asks me to create a password for the built‑in Administrator account. This account is the local superuser account before the system becomes part of a domain. I choose a strong password because even in a lab it is good practice to use secure credentials. The Administrator account will be important when I promote the server to a Domain Controller.

- Once I log in for the first time, I arrive at the Windows desktop and Server Manager may start automatically.

---

<br>
<br>

## Understanding the Administrator Account

- Before promotion to a Domain Controller, Windows has only local authentication. The Administrator account exists locally in the Security Accounts Manager. After promotion, a domain administrator account will be created and will exist in Active Directory. It is important not to confuse local Administrator with domain administrator.

- For now, I use the local Administrator to perform administrative tasks. After promotion, I will start using the domain administrator account for domain‑related work.

---

<br>
<br>

## Installing VMware Tools

- At this stage, I install VMware Tools because it improves integration between the virtual machine and VMware Workstation. VMware Tools provides better display resolution, smoother mouse integration, shared clipboard, and proper virtual hardware drivers. Without VMware Tools, graphics performance and mouse movement may feel sluggish.

- To install VMware Tools, I select "Install VMware Tools" from the VMware menu. Windows mounts a virtual disk and I follow the setup wizard.

---

<br>
<br>

## Windows Updates

- Before turning this system into a Domain Controller, I check for Windows updates. Server operating systems need regular patching, and even in a lab environment running an unpatched server can cause problems, especially with security mechanisms or required features.

- I open Settings, go to Windows Update, and install all important updates. This may require several reboots. Once updates are done, the system is more reliable and ready for role installation.

---

<br>
<br>

## Network Settings After Installation

- After Windows boots successfully, I verify that the network adapter is recognised and the system has network connectivity. At this point, VMware usually assigns an IP address using NAT or DHCP. I can see this by running "`ipconfig`" from Command Prompt.

- Although the system may have a DHCP address now, I will configure a static IP address later, because a Domain Controller should always have a stable and predictable IP. That configuration will be done in the `networking‑setup.md` file.

---

<br>
<br>

## Preparing for Domain Controller Promotion

- I do not promote the server here. Promotion will be performed only after proper <u><b>hostname</b></u>, <u><b>static IP address</b></u>, and <u><b>DNS</b></u> configuration are complete. A Domain Controller must have a <mark><b>fully qualified domain name (FQDN)</b></mark> and correct networking settings. Doing things in the wrong order can cause DNS failures later.

- At this point, the system is simply a clean Windows Server 2022 installation, fully patched, with VMware Tools installed, ready for configuration.

---

<br>
<br>

## What I Achieve After This File

- By the end of this installation, I have a working Windows Server 2022 virtual machine inside VMware. It is not yet a Domain Controller. It has only a local Administrator account and no domain roles installed.

- This clean starting point is important, because the next steps such as hostname configuration, static IP assignment, DNS preparation, and domain promotion must be done carefully in the correct sequence. Those tasks will be documented separately in later files.
