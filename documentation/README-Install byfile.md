# Overview

The meta-role `byfile` allows to manage administration tasks purely by creating files. Except for `roles/myRole/tasks/main.yml` and `roles/myRole/vars/main.yml` yaml files, no further tasks have to be specified. Most configuration tasks are directly specified in file names. To use `byfile` a standard ansible folder structure is required. An example is given below.

```
...
├── [ 48K]  files
│   ├── [4.0K]  byfile		# created and maintained by byfile
├── [8.0K]  roles_meta
│   └── [4.0K]  ansible_byfile
├── [100K]  roles
│   ├── [4.0K]  byfile -> ../roles_meta/ansible_byfile/byfile
│   ├── [ 73K]  myRole
│   │   ├── [4.7K]  tasks
│   │   │   └── [ 703]  main.yml                    # include byfile/custom plays
│   │   └── [4.4K]  vars
│   │       └── [ 403]  main.yml                    # host/user parameters
│   │   ├── [ 59K]  files
│   │   │   ├── [8.0K]  host:*                      # configure all host in role                                         
│   │   │   │   └── [4.0K]  user:*                  # all users all hosts                                          
│   │   │   ├── [8.0K]  host:myhost                 # configure host myhost                                         
│   │   │   │   └── [4.0K]  user:myuser             # configure user myuser                                          
│   │   │   │       └── [  36]  crontab rsync;0;12  # install crontab entry                              
│   │   │   │   │   └── [   0]  ...
│   │   │   ├── [ 27K]  templates                                               
│   │   │   │   ├── [5.3K]  05 @mini-role           # reusable set of confs
│   │   │   │   │   ├── [   0] ...
│   │   │   └── [4.6K]  user:*                      # configs for all users
│   │   │       ├── [ 350]  crontab:env             # define contrab env vars
│   │   │       ├── [   0]  ...
│   ├── [4.0K]  ...			# other roles
...
```

# Task specification

## Template for use with task common/install-generic.yml

Task `byfile/install-generic.yml` performs configurations according to a file based system description. The template for the `main.yml` (playbook) of a new role can be chosen as follows.

	- name: Definitions
	  include_role: { name: byfile, tasks_from: definitions.yml, apply: { tags: [ always ] } }
	  tags: [ always ]

	- name: Install standard folders
	  include_role: { name: byfile, tasks_from: install-generic.yml, apply: { tags: [ install-std ] } }
	  vars:
	    global_install_folder: "roles/myRole/files"
	    users: "{{ features[inventory_hostname]['users'] }}"
	    template_vars: "{{ features[inventory_hostname]['template_vars'] }}"
	  tags: [ install-std ]


Additional custom tasks can be added. The folder `roles/myRole/files` points to a folder structure that is documented below, triggering a number of configuration tasks.

## Terminology

Variable names *cursiv*. File names `mono spaced`.

## Folder structure

The folder structure uses a uniform folder structure "Standard folders" as specified below. The following hierarchical structure deterimines precendence across many such "Standard folders".

 * files
   * templates: files to be linked to from other folders, otherwise ignored
     * @*templatename*: installs to be softlinked into folder structure
       * byfile specifications
   * *sytemcombo* (e.g. 'openSUSE Tumbleweed_x86_64', architecture specific)
       * byfile specifications
   * host:*hostname*: installs for host *hostname*
     * host: system installs (under root)
       * byfile specifications
     * user:*: installs all users
       * byfile specifications
     * user:*username*: installs user `username`
       * byfile specifications

### byfile specification

The __byfile__ specification is a list of files the file name of which describes the configuration and the content might contain additional information needed to complete the action. The spcecification of file names is given in the [file types](#filetypes) section. Special entries are __templates__ which are folders starting with __@__. These folders will be followed recursively. Valid configuration actions are:

 * [crontab](#type_crontab): Manage crontab entry
 * [crontab:env](#type_crontab_env): Manage crontab environment
 * [dir](#type_dir): create dir
 * [extract](#type_extract): extract archive
 * [file](#type_file): install file
 * [mount](#type_mount): mount volumes
 * [package:sys](#type_package_sys): install system packages
 * [rsync](#type_rsync): rsync dir/file
 * [ssh:push](#type_ssh_push) install public user ssh key as authorized key

### Witnesses

# Variables in `vars/main.yml`

 * capabilities
   * *hostname*
	 * users
	   * { name: *username*, ssh: *booelean*, ssh_key_type: *sshtype*, ssh_key_size: *keysize*, template_vars: dict, luks: *luks_spec* }

## User vars

 * ssh: true/false, boolean to indicate wheter ssh key should be generated (needed by 
 )
 * ssh_key_tyep: rsa/ecdsa, type of ssh key (default: rsa)
 * ssh_key_size: key size for the key. Needs to be set for ecdsa with valid key sizes (256, 384, 512). Rsa has valid key sizes 2048, 4096 (default: 4096)
 * template_vars: dict containing key/value pairs used for template interpolation
 * luks: specification of luks container to be  mounted at `/home/__user__`; dict with keys:
   * password: encyrption password
   * size: size of the container (e.g. 15G)


# Files

Files (*file*) are named '*task* *path*;*user*;*group*;*permission*;*type*;*options*;*destination*'. In general, the content of the file is installed into *path* after a path transformation. All fields except for *path* can be omitted assuming default values.

Files starting with '#' are ignored.

Files starting with '^\d+-?' will have this prefix removed. Can be used to control the order of tasks.

## Path transformations

Regular paths need to start with '-' or '|'. The '-' character is interpreted as the home folder of a 'current user' that is defined by the context (i.e. the users folder above). A '|' character is interpreted as an absolute path. All '|' characters are transormed into '/' characters to form the destination path.

  * '-|' at beginning replaced with user home (current user)
  * '|' replaced by '/'
  * if *option* contains 'templatename'
    * %{user}: interpolated with name of current user (*install_user* variable)
    * __Note__: for some file types this transformation is not available (rsync)

# <a name="filetypes"></a>File types

## <a name="type_file"></a>__file__

Copy file from control host to path.

Specification: `file` *path*;*owner*;*group*;*mode*;*options(once|if_absent)*

 * *path*: encoded path of destination location
 * *owner*: onwer of the file (default: *install_user*; `root` for host files)
 * *group*: group of file (default: *install_user*; `root` for host files)
 * *mode*: file mode (default: mode of ansible file)
 * *Options*
   * once: install file only one (controlled by a witness file in the witness folder (default: /opt/ansible))
   * if_absent: only install file, if non-existing
 * __file content__: content of destination file

## <a name="type_dir"></a>__dir__

Create dir on host (mkdir -p).

 * *path*: encoded path of directory path
 * *owner*: onwer of the directory (default: *install_user*; `root` for host files)
 * *group*: group of directory (default: *install_user*; `root` for host files)
 * *mode*: directory mode (default: mode of ansible file)

## <a name="type_extract"></a>__extract__

Extract tgz, t7z, zip into destination Folder

Specification: `extract` *destdir|subdir*;*user*;*group*;*mode*;*options*

 * *destdir|subdir*: destination folder, *subdir* component specifies name of folder the top folder of the archive is renamed to
   * if *subdir* == `__ignore__`, no rename is performed
 * *user*;*group*;*mode*: ownership/access state
 * *options*:
    * `asis`: do not perform rename. *subdir* is ignored and should be named `__ignore__`. Currently, `asis` is not heeded. Instead the `__ignore__` *subdir* triggers this behavior
 * __file content__: source path of archive file

The archive should have a single folder at the top level, e.g. `/myfolder`. This folder is then moved (and renamed) to *path*.

### __Creation of archives__

Usually starts with `pushd `*destdir*. `input1` then corresponds to *subdir*.

*t7z*
Cave: `a` adds files, archive should not exist.
Several inputs `input1` are meaningful only for `asis` option.

	tar cf - input1 ... | 7za a -mx9 -si ~/tmp/myarchive.t7z
  
*tgz*

	tar czf - input1 ... | gzip -9 ~/tmp/myarchive.tgz

*zip*

	zip ~/tmp/myarchive.zip input1 ...

*zstd*

	tar cf - input | zstd -19 -z -o ~/tmp/myarchive.tzst

## __repo__

Add system repositories.

Specification: `repo` *name*;*prio*;*enabled|disabled*;*options(autoimport|no_autoimport,no_autorefresh)*

 * *name*: name of repository
 * *prio*: numeric repository priority
 * *enabled|disabled*: status of repository; either __enabled__ or __disbled__ 
 * *options(autoimport|no_autoimport,no_autorefresh)*: repostitory options; __autoimport__: import GPG keys, __no_autorefresh__: prevent automatic refresh
 * __file conent__: URL of repository

## __package__

### <a name="type_package_sys"></a>__package:sys__

Install system packages.

Specification: `package:sys` *name*;*options*;*OS*

 * *name*: name of package
 * *options*: __force__ to force (re-)installation of package
 * *OS*: specify to which OS the package list applies. Packages will only be installed when this string matches __ansible_distribution__. This should be used when packages are not installed at the host level but, for example, as part of a *@template*

__Note__: When no *OS* is specified, the value of __ansible_distribution__ is assumed. When installed in the `host` folder, the packages can be assumed to match the host. If installed in `host:*`, *OS* should be specified unless all hosts are homogeneous with respect to OS.

## __ssh__

### <a name="type_ssh_push"></a>__ssh:push__

Install the public key generated (or present) for the user as authorized key on another host.

Specification: `ssh:push` *host*;*user*

  * *host*: host to install the key on. The ansible controller has to have root access to this host
  * *user*: user to install the key under

The key itself is automatically retrieved by the user tasks and maintained in the `${ANSIBLE_HOME}/files/byfile` hierarchy.

## __line__

Control a line within *path*.

Specification: `line` *path*

  * *path*: file of which one line is to be managed
  * __file content__: two lines specifying line content
    * 1st line: regex to identify line
    * 2nd line: content of the line

The text is not templated. It is subject to the following substitutions:

 * $USER: user name
 * $HOME: path of home folder
 * $UID: user id
 * $SECRET: current secret as set by file type __secret__

## <a name="type_crontab"></a>__crontab__

Manage crontab entry.

Specification: `crontab` *name*;*min*;*hour*;*day*;*month*;*day-of-week*

  * *name*: identifier for the crontab entry
  * *min*: minutes entry of the crontab entry, or `@reboot`
  * *hour*: hour entry of the crontab entry
  * *day*: day entry of the crontab entry
  * *month*: month entry of the crontab entry
  * *day-of-week*: day-of-week entry of the crontab entry
  * __file content__: single line with the command to be executed

__Note__: A `*/min` specification has to be given as `*|min`

Examples:

  * Run on Mondays, 12:15 : `crontab myJob;15;12;*;*;1`
  * Run every 15 minutes: `crontab myJob2;*|15`

## <a name="type_crontab_env"></a>__crontab:env__

Specification: `crontab:env`

  * no file name based paramters
  * __file content__: lines with key-value pairs `KEY=VALUE`

__Note__: Implicitly defined variables `$HOME`, `$USER`, `$UID` are substituted by values corresponding to the current user.


Example content:

    USER=$USER
    HOME=$HOME
    PERL5LIB=$HOME/src/privatePerl:$HOME/lib/perl5:$HOME/perl5/lib/perl5/arm-linux-gnueabihf-thread-multi-64int

### <a name="type_rsync"></a>__rsync__

Rsync to *path*.

Specification: `rsync` *path*;*owner*;*group*;*mode*;*options*

 * *path*: destination of `rsync` operation
 * *user*: owner
 * *group*: group
 * *mode*: file/dir mode
 * __file content__: source of `rsync` operation
 
__Note__: source cannot be remote as destination will be remote; mount remote files via sshfs as a workaround


## <a name="type_mount"></a>__mount__

Specification: `mount` *mount point*;*device*;*fs type*;*options*;*pass no*;*permissions*

  * *mount point*: Path of mount point
  * *device*: Path to device (`/dev/DEV`) or `LABEL=`*devlabel`
  * *fs type*: Filsystem type
  * *options*: Options passed to `mount` (default: defaults)
  * *pass no*: Pass number in fstab (default: 2)
  * *permissions*: Permission of mount point (default: 0664)

__Note__: Fields are as usual for `fstab` entries and path transformations are applies for *device* and *mount point*.

__Example__:

  * Mount point: `|mnt|mountpoint`
  * Device: `LABEL=mylable`
  * Type: `ext4`
  * Options: `rw,relatime,noauto`
  * Filename: `mount LABEL=mylable;|mnt|mountpoint;ext4;rw,relatime,noauto`

# Old documentation


### __link__

Create symbolic link at _path_ pointing to _destination_.

### __make__

The __make__ type handles the *path* argument exceptionally.

 * *path*: Path to source package on the CMS controller
 * *user*: User under which to build the package
 * *options* (comma separated)
   * noconfigure: do not call `./configure`
   * noinstall: do not call `make install`
   * Ncores=*N*: number of cores to use (option `-j`)
   * target=*buildtarget*: specify build target as argument to `make`
   * makefile=*Makefile*: specify makefile to use (option `-f`)
   * templatename: use file name as template, current interpolation support:
     * %{user}: interpolate with install_user variable
 * File content: ignored (see makeinit)

### __makeinit__

 * File content: the file content can contain further shell initialization/installation scripts

#### File content example
 
	--------- Configure
	export CFLAGS='-fPIC -Wno-error=terminate -Wno-error=misleading-indentation'
	export PYTHON_EXECUTABLE=python3
	---------- End Configure
	---------- Install
	cp mame2016_libretro.so /usr/lib64/libretro/
	---------- End Install

A section started with `-{8,} Configure` and terminated by `-{8,} End Configure` contains a shell script run before calling `make`.

A section `-{8,} Install` and terminated by `-{8,} End Install` contains a script run after calling `make`.

### __secret__

Retrieve secret given by *path* from `secret-tool`.

The following command should used to store the secret.

	secret-tool store --label ansible.__key_used_as_path__ ansible/__key_used_as_path__ password

The command used by the this pseude-install is.

	secret-tool lookup ansible/__key_used_as_path__ password


### __shell__

Run shell command given in file content. Command execution is shielded by a witness, which has to be removed for a re-run.

*Options*

 * cdtmp: change working dir to a temporary folder

The text is not templated. It is subject to the following substitutions (see __line__):

 * $USER: user name
 * $HOME: path of home folder
 * $UID: user id
 * $SECRET: current secret as set by file type __secret__

# Packages

Folder with text files 'packages-(sys|cpanm|pip|flatpak)-.*'. Other files are ignored. In all files, empty lines and lines starting in '#' are ignored. Trailing parts of the file name can be used to describe the packages installed.

Specification: *reponame*;*prio*;*enabled|disabled*;*options*

Options:
 * force: force resolution (if supported by package manager)

## __sys__

The system package manager is used to install system packages. Ususally, these files should live in a *systemcombo* directory.

Package specification

 * *package name* (*e.g.* pdftk)
 * comment lines starting with '#'
 * empty lines

## __cpanm__

`cpanm` is used to install these packages as user local perl modules.

Package specification

 * *package name* (*e.g.* Parse::RecDecent)
 * comment lines starting with '#'
 * empty lines

## __pip__

`pip3` is used to install these packages as user local python3 modules.

Package specification

 * *package name* (*e.g.* tensorflow)
 * URL to git repo, prefixed by 'git+' (*e.g.* git+https://github.com/user/package.git)
 * comment lines starting with '#'
 * empty lines

## __flatpak__

Internal `flatpak` is used to install these packages.

Package specification

 * *package name* (*e.g.* io.freetubeapp.FreeTube)
 * comment lines starting with '#'
 * empty lines

# Services

Files of the form *service name*;enabled/disabled;started/stopped;user/system


# Best practices
