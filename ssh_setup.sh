#!/bin/bash
set -e

# --------------------------
# 🌐 Detect package manager
# --------------------------
if command -v apt >/dev/null; then
  PM="apt"
elif command -v yum >/dev/null; then
  PM="yum"
elif command -v dnf >/dev/null; then
  PM="dnf"
else
  echo "❌ Unsupported package manager. Exiting."
  exit 1
fi

# --------------------------
# 📦 Install base packages
# --------------------------
echo "🔧 Updating and installing core tools..."

if [[ "$PM" == "apt" ]]; then
  sudo apt update && sudo apt upgrade -y
  sudo apt install -y zsh git curl bat

  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt install -y nodejs nginx

elif [[ "$PM" == "yum" || "$PM" == "dnf" ]]; then
  sudo $PM update -y
  sudo $PM install -y zsh git curl

  if ! command -v bat &>/dev/null; then
    echo "⬇️ Installing bat manually..."
    curl -LO https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-0.24.0-x86_64-unknown-linux-gnu.tar.gz
    tar -xzf bat-0.24.0-*.tar.gz
    sudo mv bat-*/bat /usr/local/bin/
    rm -rf bat-0.24.0-*
  fi

  curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
  sudo $PM install -y nodejs nginx
fi

# Install PM2 globally via npm
sudo npm install -g pm2

# --------------------------
# 🐚 Oh My Zsh + Plugins
# --------------------------
echo "🐚 Installing Oh My Zsh..."
export RUNZSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Only external non-bundled plugins
declare -A plugins
plugins=(
  [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions.git"
  [fast-syntax-highlighting]="https://github.com/zdharma-continuum/fast-syntax-highlighting.git"
  [you-should-use]="https://github.com/MichaelAquilina/zsh-you-should-use.git"
  [zsh-history-substring-search]="https://github.com/zsh-users/zsh-history-substring-search.git"
)

echo "🔌 Installing external Zsh plugins..."
for plugin in "${!plugins[@]}"; do
  repo_url="${plugins[$plugin]}"
  target_dir="$ZSH_CUSTOM/plugins/$plugin"

  echo "⬇️  Cloning $plugin from $repo_url"

  if git ls-remote "$repo_url" &>/dev/null; then
    git clone --depth=1 "$repo_url" "$target_dir"
  else
    echo "⚠️  Skipping $plugin: Repo not accessible or private."
  fi
done

# --------------------------
# 🧱 Custom plugin: buildme
# --------------------------
echo "🧱 Installing custom 'buildme' plugin..."
git clone https://github.com/deveshparagiri/buildme "$ZSH_CUSTOM/plugins/buildme"

# --------------------------
# 📝 Update .zshrc
# --------------------------
echo "📝 Updating .zshrc plugin list..."
sed -i '/^plugins=/c\plugins=(git zsh-autosuggestions fast-syntax-highlighting you-should-use zsh-history-substring-search buildme npm docker conda pip python aliases kitty)' ~/.zshrc

# Alias for Ubuntu's batcat
if [[ "$PM" == "apt" ]]; then
  echo "alias bat='batcat'" >> ~/.zshrc
fi

# --------------------------
# 🐚 Set Zsh as default
# --------------------------
echo "💡 Setting Zsh as the default shell..."
chsh -s $(which zsh)

echo "✅ Done! Launch a new shell or type 'zsh' to start."
