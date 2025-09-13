echo 'HISTFILE=/workspaces/$(basename "$PWD")/.devcontainer/.bash_history' >> ~/.bashrc
echo 'HISTTIMEFORMAT="%d/%m/%y %T "' >> ~/.bashrc
# TODO: save history even if terminal is not exited before devcontainer disconnect