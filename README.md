# Overview

This document explains everything you'll need in order to set up your Windows system to run the test scripts.

If you find that you have setup questions that are not adequately answered by this document, please contact QA for help.

# Ruby Setup

Go [here](http://rubyinstaller.org/downloads) to get the installer for version 1.9.3. Run it.

Make *sure* that you add Ruby to your path (it will give you this option during installation, and the default is *OFF*, so pay close attention).

# Watir Setup

Open a command prompt, making sure you're running the window with administrator privileges.

Type the following at the prompt:


`gem update --system`

Now you're ready to install Watir itself!

Once that's done, do this:

`gem install 'watir-webdriver'`

# SQLite3

1) At a command prompt:

`gem install 'sqlite3'`

2) Get the SQLite3 source code from [the download page](http://www.sqlite.org/download.html). You're going to want to download the zip files with the "precompiled binaries" and the DLL (The description will say something like "This ZIP archive contains a DLL for the SQLite library version XXX").

The three files you care about are:

sqlite3.dll
sqlite3.exe
sqlite3.def

Strictly speaking, the only file truly *needed* is the *dll*. The EXE is in case you want to interact with a DB outside of Ruby scripts. I have no idea what the def file is for.

These files should be unzipped and placed in the Ruby install's "bin" folder.

# Page Object

Next:

`gem install 'page-object'`

# Chrome Driver

In order to be able to run Chrome, you need to install the chrome driver. That is found via this page here: [http://code.google.com/p/chromium/downloads/list]

Get the proper version for your system.

Unzip the file and put the executable into your Ruby/bin folder.

# Script Setup

Put all the scripts you're going to run into the same local folder on your system. This should be the folder that you've already defined in the Subversion Setup section above.

The scripts will go into various subfolders, as required

# Config.yml
Please rename the `config.yml.template` file that comes with the code to `config.yml` and update it with the appropriate information. Follow the directions contained in the file.

# Cipher.rb
This file contains a FetchBack secret key and should not be shared around. If you got the scripts from the repository on github then this file is not included with the rest and must be obtained from the SVN repository and placed in the `retargeting` folder.

# Keywords.yml
Please rename the `keywords.yml.template` file to `keywords.yml` or, better yet, get the latest version of it from Ben, as I'm sure he's got more keywords listed in his than there are in the template file.

# Blacklist.yml
Do the same for this file as you did for the keywords.yml file.

# Hosts File

If you're running a Windows box then you're going to need a quick way to update your Hosts file with pointers to the various test machines.