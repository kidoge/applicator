# Applicator

Applicator is a bash script for installing configuration files into home directory.

It can apply configuration files from a local filesystem, or download the source from a GitHub repository.

When github user account is specified, it looks at applicator-config repository be default. However, this can be specified by entering the repository name after colon.

Example usage:

```
./applicator test/.bashrc # Applies .bashrc from local filesystem
./applicator githubuser # Installs config files from github.com/githubuser/applicator-config
./applicator user:repo # Installs config files from github.com/user/repo
```

If there are existing files, it will ask the user whether to overwrite, merge or skip.
And it will always make a backup of existing configuration files before making any changes.

As an alternative to cloning the applicator repository, the user can also download and execute the launcher script.
This will clone applicator to a temporary directory, excecute it, then clean up after itself, ideal for one-off setup scenarios.
