# ansbile_byfile

## Introduction

Ansible role that allows file-based admintistration for heterogeneous environments. In most cases, no playbooks are required and boilerplate free administration is possible.

## Documenation

Filenames and sometimes file content contain all information for the administration task. Filder `documentation` describes all supported tasks.

## Installaion

Subfolder `byfile` has to be linked into the `roles` folder of ansible. It is suggested to create a foler `roles_meta` in the ansible folder and clone this repo into this folder. Under these assumptions, `bash install.sh` will create the required softlink.

Suggested tree

```
├── [   6]  b -> books/
├── [8.0K]  books
├── [4.0K]  documentation
├── [ 48K]  files
│   ├── [4.0K]  byfile		# created and maintained by byfile
├── [4.0K]  group_vars
├── [100K]  roles
│   ├── [4.0K]  byfile -> ../roles_meta/ansible_byfile/byfile
│   ├── [4.0K]  ...			# other roles
├── [8.0K]  roles_meta
│   └── [4.0K]  ansible_byfile
```
