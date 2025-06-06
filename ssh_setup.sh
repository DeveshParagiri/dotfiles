#!/bin/bash

set -e

echo "🔧 Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "📦 Installing core dependencies: zsh, git, curl, bat, node, nginx, pm2..."

# Zsh, Git, Curl, Bat
sudo apt install -y zsh git curl bat

# Node.js (via NodeSource for latest LTS)
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# Nginx
sudo apt install -y nginx

# PM2 globally via npm
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
echo "🟡 Note: On Ubuntu, 'bat' is installed as 'batcat'. You can alias it using:"
echo "alias bat='batcat'" >> ~/.zshrc
