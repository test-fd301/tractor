TractoR consists of several R packages and a set of other files which provide
an interface to key functions within those packages. The interface requires a
"bash" shell, and is therefore only designed to work on Unix-like operating
systems, such as Linux or Mac OS X. In particular, it will not work directly on
Windows, and Windows users are therefore recommended to run Linux within a
virtual machine, and then install TractoR (and R) within that virtual
environment. The virtual machine image provided by the
[FSL package](http://www.fmrib.ox.ac.uk/fsl/) is one suitable example.


Quick installation for knowledgeable users
------------------------------------------

1. Install R if necessary. See <http://www.r-project.org>.

2. Open a terminal, navigate to the uncompressed "tractor" directory and type
`make install-all`. If a C/C++ compiler is not available, `make install` can be
used instead.

3. Create or update the `TRACTOR_HOME` environment variable to point to the
"tractor" directory, include `${TRACTOR_HOME}/bin` on the `PATH` and
`${TRACTOR_HOME}/man` on the `MANPATH`.

4. Consider installing [ImageMagick](http://www.imagemagick.org/) and/or
[FSL](http://www.fmrib.ox.ac.uk/fsl/) if they are not already installed. They
are used by some elements of TractoR's functionality.


Details and step-by-step explanation
------------------------------------

Before installing TractoR, R must be installed. R runs on almost all platforms
and is simple to install. It can be obtained from <http://www.r-project.org>.

Once R is installed, the TractoR R packages can be installed by opening a
terminal window and running

    make install

from the uncompressed "tractor" directory. If you also wish to install the
native packages, which provide faster tractography and parallel processing
capabilities, type

    make install-native

A C/C++ compiler must be available for this to work, but R will handle all of
the code compilation details for you. To test that the installation was
successful, type

    make clean test

and a series of standard tests will be run.

For the "tractor" interface to function correctly, the TRACTOR_HOME and PATH
environment variables should be set appropriately. To do this, add the
following lines to your `~/.bashrc` (or equivalent for other shells):

    export TRACTOR_HOME=/usr/local/tractor
    export PATH=${TRACTOR_HOME}/bin:${PATH}
    export MANPATH=${TRACTOR_HOME}/man:${MANPATH}

(Note that the first line may need to be modified to reflect the actual
location of the uncompressed "tractor" directory on your system.) To make sure
that "login" shells also pick up these variables, you may also wish to point
your `~/.bash_profile` at `~/.bashrc`. This can be achieved with the line

    [ -f ~/.bashrc ] && source ~/.bashrc

in `~/.bash_profile` (create this file if it doesn't exist). To check that
everything is functioning correctly, you can try the following commands after
opening a new terminal window:

    cat ${TRACTOR_HOME}/VERSION   # should print the current TractoR version
    man tractor                   # should open the "tractor" man page
    tractor -z list               # should list the TractoR scripts installed

For further information on using the TractoR interface, type `tractor -h` or
take a look at the man page. To find out what a particular script does, type
`tractor -o (script_name)`, replacing `(script_name)` with the name of the
script you are interested in.

Finally, you may want to consider also installing
[ImageMagick](http://www.imagemagick.org/) and/or
[FSL](http://www.fmrib.ox.ac.uk/fsl/), if they are not already installed. They
are used by some elements of TractoR's functionality, so installing both will
avoid any problems with missing software later.
