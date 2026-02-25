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
│   │   │   │   └── [4.0K]  host                    # host configuration                                          
│   │   │   │       └── [ 536]  file |ect|nanorc    # file task (on each host)                              
│   │   │   │   └── [ 536]  file |ect|nanorc        # if not 'host' subfolder exists
                                                    # tasks are taken from host:*
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

The __byfile__ specification is a list of files the file name of which describes the configuration and the content might contain additional information needed to complete the action. The specification of file names is given in the [file types](#filetypes) section. Special entries are __templates__ which are folders starting with __@__. These folders will be followed recursively. Valid configuration actions are:

 * [crontab](#type_crontab): Manage crontab entry
 * [crontab:env](#type_crontab_env): Manage crontab environment
 * [dir](#type_dir): create dir
 * [extract](#type_extract): extract archive
 * [file](#type_file): install file
 * [line](#type_line): control line within file
 * [link](#type_link): create symbolic link
 * [make](#type_make): run make on an archive
 * [mount](#type_mount): mount volumes
 * [package](#type_package): install packages
 * [package:cpanm](#type_package_cpanm): install local perl packages
 * [package:flatpak](#type_package_flatpak): install flathub packages
 * [package:pip](#type_package_pip): install local python packages
 * [package:sys](#type_package_sys): install system packages
 * [repo](#type_repo): add system repository
 * [rsync](#type_rsync): rsync dir/file
 * [secret](#type_secret): retrieve secret from keyring
 * [service](#type_service): Manage systemd services
 * [shell](#type_shell): Run shell command
 * [ssh:push](#type_ssh_push): install public user ssh key as authorized key

### Witnesses

# Variables in `vars/main.yml`

 * capabilities
   * *hostname*
	 * users
	   * { name: *username*, ssh: *booelean*, ssh_key_type: *sshtype*, ssh_key_size: *keysize*, template_vars: dict, luks: *luks_spec* }

## User vars

 * ssh: true/false, boolean to indicate wheter ssh key should be generated (needed by 
 )
 * ssh_key_type: rsa/ecdsa, type of ssh key (default: rsa)
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

## <a name="type_link"></a>__link__

Create symbolic link.

Specification: `link` *path*;*owner*;*group*;*mode*;*options*

 * *path*: encoded path of where symbolic link location (link destination)
 * *owner*: onwer of the file (default: *install_user*; `root` for host files)
 * *group*: group of file (default: *install_user*; `root` for host files)
 * *mode*: file mode (default: mode of ansible file)
 * *Options*: none defined
 * __file content__: path of file which the symbolic links points to (link source)

__Note__: `~` is allowd to indicate home folder of current user

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

__Note__: The archive should have a single folder at the top level, e.g. `/myfolder`. This folder is then moved (and renamed) to *path*.

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

## <a name="type_repo"></a>__repo__

Add system repositories.

Specification: `repo` *name*;*prio*;*enabled|disabled*;*options(autoimport|no_autoimport,no_autorefresh)*;*OS*

 * *name*: name of repository
 * *prio*: numeric repository priority
 * *enabled|disabled*: status of repository; either __enabled__ or __disbled__ 
 * *options(autoimport|no_autoimport,no_autorefresh)*: repostitory options; __autoimport__: import GPG keys, __no_autorefresh__: prevent automatic refresh
 * *OS*: specify to which OS the package list applies. Packages will only be installed when this string matches __ansible_distribution__. This should be used when packages are not installed at the host level but, for example, as part of a *@template*
 * __file conent__: URL of repository

__Note__: String `${relversion}` is replaced with the value of ansible variable *ansible_distribution_version*.

## <a name="type_package"></a>__Packages__

Files 'package:(sys|cpanm|pip|flatpak) *description*' are used to install packages from different sources.

### <a name="type_package_sys"></a>__package:sys__

Install system packages.

Specification: `package:sys` *description*;*options*;*OS*

 * *description*: description of packages installed by the file
 * *options*: __force__ to force (re-)installation of package
 * *OS*: specify to which OS the package list applies. Packages will only be installed when this string matches __ansible_distribution__. This should be used when packages are not installed at the host level but, for example, as part of a *@template*
 * __file conent__
   * each line specifies name of a package
   * Empty lines are ignored
   * Lines beginning with '#' are ignored.

__Note__: When no *OS* is specified, the value of __ansible_distribution__ is assumed. When installed in the `host` folder, the packages can be assumed to match the host. If installed in `host:*`, *OS* should be specified unless all hosts are homogeneous with respect to OS.

### <a name="type_package_cpanm"></a>__package:cpanm__

Install packages from cpan.

Specification: `package:cpanm` *name*;*options*

 * *description*: description of packages installed by the file
 * *options*: __force__ to force (re-)installation of package
 * __file conent__
   * each line specifies name of a package
   * Empty lines are ignored
   * Lines beginning with '#' are ignored.

### <a name="type_package_pip"></a>__package:pip__

Install packages from PyPI.

Specification: `package:pip` *name*;*options*

 * *description*: description of packages installed by the file
 * *options*: __force__ to force (re-)installation of package
 * __file conent__
   * each line specifies name of a package/URL
   * URL to git repo, prefixed by 'git+' (*e.g.* git+https://github.com/user/package.git)
   * Empty lines are ignored
   * Lines beginning with '#' are ignored.

__Note__: `pip3` is used to install these packages as user local python3 modules.

### <a name="type_package_flatpak"></a>__package:flatpak__

Install packages using flatpak.

Specification: `package:flatpak` *name*;*options*

 * *description*: description of packages installed by the file
 * *options*: __force__ to force (re-)installation of package
 * __file conent__
   * each line specifies name of a package/URL
   * Empty lines are ignored
   * Lines beginning with '#' are ignored.

__Note__:  Command `flatpak` is used to install the packages. This task depends on proper setup of a flatpak repository.

 
## __ssh__

### <a name="type_ssh_push"></a>__ssh:push__

Install the public key generated (or present) for the user as authorized key on another host.

Specification: `ssh:push` *host*;*user*

  * *host*: host to install the key on. The ansible controller has to have root access to this host
  * *user*: user to install the key under

The key itself is automatically retrieved by the user tasks and maintained in the `${ANSIBLE_HOME}/files/byfile` hierarchy.

## <a name="type_line"></a>__line__

Control a line within *path*.

Specification: `line` *path*;*tag*

  * *path*: file of which one line is to be managed
  * *tag*: if several lines are to be controlled in a file, a *tag* can be used to disambiguate file names
  * __file content__: two lines specifying line content
    * 1st line: regex to identify line
    * 2nd line: content of the line

The text is not templated. It is subject to the following substitutions:

 * $USER: user name
 * $HOME: path of home folder
 * $UID: user id
 * $SECRET: current secret as set by file type __secret__

Example:

```
# BORG BACKUP ansible$
export BORG_PASSPHRASE="$SECRET" # BORG BACKUP ansible
```

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

Specification: `crontab:env *description*`

  * no file name based parameters
  * *description* can be used to document the content and is ignored 
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

Manage volume mounting.

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

## <a name="type_service"></a>__sevice__

Manage systemd services.

Specification: `service` *service name*;*boot status*;*momentary status*;*type* no*;*permissions*

  * *service name*: name of the service to be managed
  * *boot status*: activation of service at boot time: enabled/disabled
  * *momentary status*: status after ansible run: started/stopped
  * *type*: type of service: user/system

## <a name="type_make"></a>__make__

Run make on archive.

Specification: `make` *path*;*user*;*group*;*options*;*pass no*;*permissions*

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
 * __file content__: the file content can contain further shell initialization/installation scripts

__File content specification__

A section started with `-{8,} Configure` and terminated by `-{8,} End Configure` contains a shell script run before calling `make`.

A section `-{8,} Install` and terminated by `-{8,} End Install` contains a script run after calling `make`.

__Example__ (file content):

	--------- Configure
	export CFLAGS='-fPIC -Wno-error=terminate -Wno-error=misleading-indentation'
	export PYTHON_EXECUTABLE=python3
	---------- End Configure
	---------- Install
	cp mame2016_libretro.so /usr/lib64/libretro/
	---------- End Install

## <a name="type_secret"></a> __secret__

Retrieve secret using `secret-tool`.

Specification: `secret` *key*;*attribute*

 * *key*: key to be retrieved from keyring
 * *attribute*: attribute to provide to secret-tool (default: password)

The variable *$SECRET* is substituted in where applicable: *shell*, *line*.

__Keyring details__

The following command should used to store the secret.

	secret-tool store --label ansible.__key_used_as_path__ ansible/__key_used_as_path__ password

The command used by the this pseude-install is.

	secret-tool lookup ansible/__key_used_as_path__ password



## <a name="type_shell"></a>__shell__

Run shell command given in file content. Command execution is shielded by a witness, which has to be removed for a re-run.

Specification: `shell` *name*;*user*;*group*;*options*

 * *name*: name of the script, documentation only
 * *user*: user to run under
 * *group*: ignored
 * *options*
   * cdtmp: change working dir to a temporary folder

The text is not templated. It is subject to the following substitutions (see __line__):

 * $USER: user name
 * $HOME: path of home folder
 * $UID: user id
 * $SECRET: current secret as set by file type __secret__


# Best practices

## Ad-hoc hosts

For ad-hoc chnages it is recommended to add a new folder *host*-adhoc which has to be added to the *$ANSIBLE_HOME/hosts* file and as an alias to *~/.ssh/config*. Files created here ad-hoc can be moved to the main host folder after the ad-hoc changes.

