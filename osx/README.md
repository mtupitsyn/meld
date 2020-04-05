Meld for OS X
===========

This README should help you build Meld for OS X.

### Preparing JHBuild Environment ###

JHBuild is the build system that we will be using to build Meld. This step should really be done once and further builds should not require updating the build environment unless there have been some updates to the libraries that you'd like to do.

#### Environment

To ensure that we don't hit some issue with python not able to determine locales on OSX, let's do the following

```
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
```

#### Initial Phase - JHBuild

1. Install Command Line Tools
```
xcode-select --install
```

1. Install brew if you don't have it
```bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

2. Clean any previous `jhbuild` setup
```bash
rm -rf ~/bin/jhbuild ~/.local/bin/jhbuild ~/.local/share/jhbuild ~/.cache/jhbuild ~/.config/jhbuildrc ~/.jhbuildrc ~/jhbuild
```

3. Ensure Python3 (required by new jhbuild) is used during the setup
```bash
brew install python3 ccache
mkdir -p ~/.new_local/bin
ln -sf /usr/local/bin/python3 ~/.new_local/bin/python

# We need to ensure that we don't taint the path during this phase with anything from brew or ports
export PATH="${HOME}/.new_local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
```

4. Install jhbuild
```bash
curl -OL https://gitlab.gnome.org/GNOME/gtk-osx/raw/master/gtk-osx-setup.sh
bash gtk-osx-setup.sh

# You will be asked whether to use own Python. I chose Yes
Would you like us to install CPython 3.6.9 with pyenv? [Y/n]: Y

# Put jhbuild in our own path
mkdir -p ~/bin
ln -sf ~/.new_local/bin/jhbuild ~/bin/jhbuild

# And backup the original configuration that comes with it
[ -f ~/.config/jhbuildrc-custom.orig ] || cp ~/.config/jhbuildrc-custom ~/.config/jhbuildrc-custom.orig
```

5. Clone Meld and use our own custom jhbuildrc
```bash
git clone https://github.com/yousseb/meld.git
(cd meld/osx && ln -sf ${PWD}/jhbuildrc-custom ${HOME}/.config/jhbuildrc-custom)
```

#### Preparing Python3/GTK Environment
1. Ensure that you have ccache
```bash
brew install ccache
```

2. Ensure that PATH is not tainted
```bash
export PATH="${HOME}/.new_local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
```

3. Build the environment
```bash
cd meld
bash ./osx/build_env.sh
```
This is a very long process depending on your CPU and your Mac load. One an old Core i7 (late 2012), it's about two to three hours.


### Building Meld

This isn't right yet. Work in progress.
```
chmod +x osx/build_app.sh
jhbuild run osx/build_app.sh
```
or
```
jhbuild shell
chmod +x osx/build_app.sh
./osx/build_app.sh
```

#### Output ####

:bulb:**Output:** Find the output dmg file in osx/Archives after you're done building.

