#! /bin/sh
mkdir -p ~/.config/fish/completions && ln -s ~/.asdf/completions/asdf.fish ~/.config/fish/completions

asdf plugin add ruby
asdf plugin add nodejs
asdf plugin add rust
asdf plugin add golang
asdf plugin add java
asdf plugin add python

asdf plugin-add direnv
asdf direnv setup --shell fish --version latest
asdf global direnv latest