<div align="center">

# asdf-eza
An [asdf](https://asdf-vm.com) plugin for managing [eza](https://github.com/eza-community/eza) versions.
</div>

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

- `zsh`, `curl`, `tar`.

# Install

Plugin:

```shell
asdf plugin add eza https://github.com/adam-du-nz/asdf-eza.git
```

eza:

```shell
# Show all installable versions
asdf list-all eza

# Install specific version
asdf install eza latest

# Set a version globally (on your ~/.tool-versions file)
asdf global eza latest

# Now zoxide commands are available
ezq --version
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.

# License

`asdf-eza` is more almost direct copy of [asdf-zoxide](https://github.com/nyrst/asdf-zoxide) by [nyrst](https://github.com/nyrst); kudos!

See [LICENSE](LICENSE) © [Siegfried Ehret](https://github.com/SiegfriedEhret/)
