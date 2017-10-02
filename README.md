# Conda Bootstrap Script

As you might expect, this script installs conda.
Here are some parameters that might be useful while installing:
 
- `OS_TYPE`: Use either `Linux-x86_64.sh` or `MacOSX-x86_64.sh` Default: `Linux-x86_64.sh`
- `MINICONDA_VARIANT`: Specifies Python 2 vs Python 3(Specified with `2` or `3`, respectively). Default: `3`
- `MINICONDA_VER`: Specifies which version of Miniconda to install. Default: 'latest'
- `PROFILE_FILE`: Specifies user's preferred config file. Default: `/etc/profile`. Common alternatives might be `~/.bashrc` or `~/.zshrc`
- `CONDA_INSTALL_PATH`: Location to install conda. Default: `/opt/conda`
- `PROJ_DIR`: Directory to be used for installing Miniconda. Default: `$PWD`

** Note on setting `PROFILE_FILE`, `PROFILE_DIR`, and `CONDA_INSTALL_PATH`:

- These values will determine where the installation/configuration of `conda` is saved, and they will have to be known to use conda on future logins.
  - In particular, `PROFILE_FILE` and `PROFILE_DIR` will need to be `source`-ed on login, so make sure your `.bashrc`/`.zshrc`/`.profile`/etc source them if they are not set to a non-default location.
  - `CONDA_INSTALL_PATH` will contain the `conda` binary, so you'll want `$CONDA_INSTALL_PATH/bin` on your `PATH` and you'll want `CONDA_BIN_PATH` to be set to that value. If you want access to conda on login, make sure your init files set these values accordingly.
