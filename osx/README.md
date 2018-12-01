Meld for OS X
===========

	This README should help you build Meld for OS X.

	:bulb:**Tip:** A lot of people are asking how to use this package as a git difftool.
	Once installed, edit your ```~/.gitconfig```, and add the following lines
	 ```
		[diff]
			tool = meld
		[difftool]
			prompt = false
		[difftool "meld"]
			trustExitCode = true
			cmd = /Applications/Meld.app/Contents/MacOS/Meld \"$LOCAL\" \"$PWD/$REMOTE\"
	  ```

### Preparing JHBuild Environment ###

	JHBuild is the build system that we will be using to build Meld. This step should really be done once and further builds should not require updating the build environment unless there have been some updates to the libraries that you'd like to do.

#### Preparation ####

To ensure that we don't hit some issue with python not able to determine locales on OSX, let's do the following

	```
	export LC_ALL=en_US.UTF-8
	export LANG=en_US.UTF-8
	```

#### Initial Phase ####

 1. Download the setup script
	```
	cd ~
	curl -O https://git.gnome.org/browse/gtk-osx/plain/gtk-osx-build-setup.sh
	```

 2. Run the setup script
	```
	sh gtk-osx-build-setup.sh
	~/.local/bin/jhbuild shell
	```
	You can exit the shell once you determine that it works properly

 3. Prepare build environment
	```
	export PATH="~/.local/bin/:$PATH"
	brew install ccache
	(cd osx && ./build_env.sh)
	```

 4. Checkout meld and start the initial phase
	```
	git clone https://github.com/yousseb/meld.git
	cd meld
	cd osx/
	ln -sf $PWD/jhbuildrc-custom ~/.jhbuildrc-custom
	cd ..
	```

#### Building Meld ####
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

	> :bulb:**Output:** Find the output dmg file in osx/Archives after you're done building.

#### FAQ ####

1. Can't run jhbuild bootstrap - gives an error related to bash not being found.
	```
	mkdir -p $HOME/gtk/inst/bin; 
	ln -sf /bin/bash $HOME/gtk/inst/bin/bash
	```
