# 🔐 PICOPI VAULT (v1.0)

**PICOPI** is a lightweight, high-security password manager built entirely in Bash for Linux environments. It leverages industry-standard GPG encryption and a Git-based workflow to ensure your credentials are secure, audited, and synced across your devices.

---

## 🚀 Features

- **Zero-Knowledge Encryption**: Powered by GPG (Symmetric AES-256)
- **Security Audit Logs**: Tracks access timestamps in a hidden local ledger
- **Anti-Brute Force**: Integrated 3-strike system with a 30-second hardware-level lockdown animation
- **Cloud Sync**: Native Git integration for private repository backups
- **Secure Retrieval**: Automated clipboard management with a 10-second visual countdown
- **Cyberpunk UI**: Fully colorized ANSI interface with ASCII splash screens

---

## 🛠 Installation

### 1. Prerequisites

Ensure you have the necessary Linux utilities installed:

```bash
sudo apt update && sudo apt install gpg xclip git -y
```

### 2. Setup the Vault

Create your hidden vault directory and set strict permissions:

```bash
mkdir -p ~/.myvault
chmod 700 ~/.myvault
```

### 3. Install the Script

Move the PICOPI script to your local binaries and make it executable:

```bash
mkdir -p ~/.local/bin
# Assuming you named your script file 'picopi_vault_fixed.sh'
cp picopi_vault_fixed.sh ~/.local/bin/picopi
chmod +x ~/.local/bin/picopi
```

### 4. Update your PATH

Add this to your `~/.bashrc` or `~/.zshrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then reload your shell:

```bash
source ~/.bashrc  # or source ~/.zshrc
```

### 5. (Optional) Initialize Git Repository

To enable cloud synchronization, initialize a Git repository in your vault:

```bash
cd ~/.myvault
git init
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Add a .gitignore to protect sensitive logs
echo ".vault_log" > .gitignore
git add .gitignore
git commit -m "Initial commit"

# Link to your private remote repository
git remote add origin https://github.com/yourusername/your-private-vault.git
git branch -M main
git push -u origin main
```

**⚠️ IMPORTANT**: Make sure your remote repository is **PRIVATE**. Never use a public repository for your password vault.

---

## 📖 Usage

Run PICOPI from anywhere in your terminal:

```bash
picopi
```

### Main Menu Options

1. **➕ Add New Password** - Store a new encrypted credential
2. **🔑 Retrieve Password** - Decrypt and copy password to clipboard (auto-clears after 10 seconds)
3. **🎲 Generate Strong Pass** - Create a random 20-character password
4. **📂 List All Vaults** - View all stored service names
5. **📜 View Security Logs** - Check access history
6. **🔄 Force Cloud Sync (Git)** - Manually push/pull changes to your remote repository
7. **🚪 Secure Exit** - Lock and close PICOPI session

---

## 📂 System Architecture

```
Input → Encryption → Storage → Sync
  ↓         ↓          ↓        ↓
User    GPG AES-256  .gpg    GitHub
              ↓       files   (Private)
         Direct pipe
       (no plaintext)
```

1. **Input**: User provides service name and password
2. **Encryption**: Data is piped directly to GPG to avoid plain-text disk writes
3. **Storage**: Encrypted `.gpg` files are stored in `~/.myvault/`
4. **Sync**: Changes are automatically committed and pushed to your linked private GitHub repository

---

## ⚠️ Security Notes

### 🔑 Master Password
- PICOPI does not store your master password
- If you lose it, **your data is unrecoverable**
- Use a strong, memorable passphrase

### 🔒 Local Security
- Always ensure `~/.myvault` permissions stay at `700`
- Never share your vault directory with other users
- Keep your system secure and up-to-date

### 🌐 Git Stealth
- The `.vault_log` is automatically ignored by Git to prevent leaking your account list to the cloud
- Always use a **PRIVATE** repository
- Consider using SSH keys instead of HTTPS for authentication

### 🛡️ Anti-Brute Force
- 3 failed decryption attempts trigger a 30-second lockdown
- All access attempts are logged with timestamps
- Review logs regularly for suspicious activity

### 📋 Clipboard Security
- Retrieved passwords are automatically cleared from clipboard after 10 seconds
- A visual countdown timer shows remaining time
- Avoid pasting passwords in untrusted applications

---

## 🔧 Troubleshooting

### "xclip: command not found"
Install xclip:
```bash
sudo apt install xclip -y
```

### Git sync fails
Check your remote repository configuration:
```bash
cd ~/.myvault
git remote -v
```

Ensure you have push permissions and your credentials are configured.

### GPG encryption fails
Verify GPG is installed and working:
```bash
gpg --version
```

Test encryption manually:
```bash
echo "test" | gpg --symmetric --cipher-algo AES256 -o test.gpg
```

### Permission denied errors
Reset vault permissions:
```bash
chmod 700 ~/.myvault
chmod 600 ~/.myvault/*
```

---

## 🗂️ File Structure

```
~/.myvault/
├── .git/                    # Git repository (if initialized)
├── .gitignore              # Protects .vault_log from being committed
├── .vault_log              # Access audit log (local only)
├── service1.gpg            # Encrypted password files
├── service2.gpg
└── service3.gpg
```


---


## 🙏 Acknowledgments

- **GPG** - The GNU Privacy Guard team
- **Git** - Linus Torvalds and the Git community
- **xclip** - For clipboard management on Linux

---

## 📞 Support

For issues or questions:
- Check the Troubleshooting section above
- Review your system logs
- Verify all dependencies are installed

**Remember**: This tool provides strong encryption, but security also depends on your practices. Use strong passphrases, keep your system secure, and never share your vault.

---

**Stay Secure! 🔐**