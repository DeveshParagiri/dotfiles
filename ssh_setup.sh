#!/bin/bash
set -e

# Detect package manager
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

echo "🔧 Updating system packages..."
if [[ "$PM" == "apt" ]]; then
  sudo apt update && sudo apt upgrade -y
else
  sudo $PM update -y
fi

echo "📦 Installing core dependencies: zsh, git, curl, node, nginx, pm2, bat..."

# Base packages
if [[ "$PM" == "apt" ]]; then
  sudo apt install -y zsh git curl bat

  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt install -y nodejs nginx

elif [[ "$PM" == "yum" || "$PM" == "dnf" ]]; then
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

# PM2 via npm
sudo npm install -g pm2

echo "🐚 Installing Oh My Zsh..."
export RUNZSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

echo "🔌 Installing Zsh Plugins..."
declare -A plugins
plugins=(
  [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions.git"
  [fast-syntax-highlighting]="https://github.com/zdharma-continuum/fast-syntax-highlighting.git"
  [you-should-use]="https://github.com/MichaelAquilina/zsh-you-should-use.git"
  [zsh-bat]="https://github.com/eth-p/zsh-bat.git"
  [web-search]="https://github.com/lukechilds/zsh-web-search.git"
  [virtualenv]="https://github.com/yyuu/pyenv-virtualenv.git"
  [npm]="https://github.com/lukechilds/zsh-npm-scripts.git"
  [docker]="https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/docker"
  [zsh-history-substring-search]="https://github.com/zsh-users/zsh-history-substring-search.git"
  [conda]="https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/conda"
  [pip]="https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/pip"
  [python]="https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/python"
  [aliases]="https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/aliases"
  [kitty]="https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/kitty"
)

for plugin in "${!plugins[@]}"; do
  repo_url="${plugins[$plugin]}"
  if [[ $repo_url == *"tree/master/plugins"* ]]; then
    echo "✅ Skipping $plugin (bundled with oh-my-zsh)"
  else
    echo "⬇️  Cloning $plugin from $repo_url"
    git clone "$repo_url" "$ZSH_CUSTOM/plugins/$plugin"
  fi
done

echo "🧱 Installing custom 'buildme' plugin..."
git clone https://github.com/deveshparagiri/buildme "$ZSH_CUSTOM/plugins/buildme"

echo "📝 Updating .zshrc plugin list..."
sed -i '/^plugins=/c\plugins=(git zsh-autosuggestions fast-syntax-highlighting you-should-use zsh-bat web-search virtualenv npm docker zsh-history-substring-search conda pip python aliases buildme kitty)' ~/.zshrc

echo "💡 Setting Zsh as the default shell..."
chsh -s $(which zsh)

echo "✅ Done. Start a new shell or type 'zsh' to switch!"
if [[ "$PM" == "apt" ]]; then
  echo "🟡 Note: On Ubuntu, 'bat' is installed as 'batcat'. You can alias it using:"
  echo "alias bat='batcat'" >> ~/.zshrc
fi
