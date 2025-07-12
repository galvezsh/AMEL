# AMEL - Automated Memory Extractor for Linux

**AMEL** is a collection of Bash scripts that automate the process of capturing live system memory and creating Volatility-compatible Linux memory profiles. It is designed to simplify forensic memory acquisition and analysis for Linux systems.

This project includes three separate scripts, each tailored to a specific Linux family:

- ✅ `amel_deb.sh` – For **Debian-based distributions** (Ubuntu, Kali, Linux Mint, etc.)
- ✅ `amel_rpm.sh` – For **RPM-based distributions** (Fedora, CentOS, RHEL, AlmaLinux, etc.)
- ✅ `amel_arch.sh` – For **ARCH-based distributions** (Arch Linux, Manjaro, EndeavourOS, Garuda Linux, etc.)

## 📌 Features

- 🔒 Securely captures live RAM using [AVML (Azure Virtual Machine Memory Dump Tool)](https://github.com/microsoft/avml)
- 🧠 Builds Linux memory profiles compatible with [Volatility 2](https://github.com/volatilityfoundation/volatility)
- 🔁 Automatically installs necessary dependencies
- 🗂️ Organizes memory dumps and profiles into timestamped folders
- 🧾 Generates a pre-filled `volatilityrc` file for fast analysis

## 📂 Scripts Overview

| Script         | Target System Type     | Package Manager  | Python Version | Tool Installer  |
|----------------|------------------------|------------------|----------------|-----------------|
| `amel_deb.sh`  | Debian/Ubuntu-based    | `apt-get`        | `python3`      | `apt-get`       |
| `amel_rpm.sh`  | Fedora/RHEL-based      | `dnf`            | `python3`      | `dnf`           |
| `amel_arch.sh` | Arch/Manjaro-based     | `pacman`         | `python3`      | `pacman`        |

Each script is self-contained and handles the following:

- Dependency installation
- Tool validation and cloning (Volatility2 and AVML)
- RAM capture prompt
- Profile creation prompt

## 🚀 How to Use

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/amel.git
cd amel
```
### 2. Run the script based on your distro

- For Debian/Ubuntu-based systems

```bash
sudo ./amel_deb.sh
```

- For Fedora/CentOS-based systems
```bash
sudo ./amel_rpm.sh
```

- For Arch/Manjaro-based systems
```bash
sudo ./amel_arch.sh
```

## 🧪 Example Interaction 

```plaintext
Do you want to capture the RAM? (y/n): y
[ RAM captured successfully ]

Do you want to create the profile for volatility? (y/n): y
[ Volatility profile created successfully ]
```

## 🗃️ Output Structure

```plaintext
capture/
└── memorydump_2025-07-12_14:32:10/
    ├── ubuntu_memorydump.mem
    ├── ubuntu_profile.zip
    └── volatilityrc
```

## ⚙️ Requirements

- Root privileges (sudo)
- Internet connection
- Git and build tools (installed automatically)
- Linux with a supported kernel version

## 🤝 Credits

- Volatility Foundation
- Microsoft AVML
- Script created and maintained by [Galvezsh]

## 📄 License

This project is licensed under the MIT License.