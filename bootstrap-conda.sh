#!/bin/bash
set -e


# 0. Specify Miniconda version
## 0.1 A few parameters
## specify base operating system
if [[ ! -v OS_TYPE ]]; then
    echo "OS_TYPE not set, setting  ..."
    OS_TYPE="Linux-x86_64.sh"
    echo "Set OS_TYPE to $OS_TYPE"
fi
## Python 2 or 3 based miniconda?
if [[ ! -v MINICONDA_VARIANT ]]; then
    echo "MINICONDA_VARIANT not set, setting ... "
    MINICONDA_VARIANT="3"  #for Python 3.5.x
    echo "Set MINICONDA_VARIANT to $MINICONDA_VARIANT"
fi
## specify Miniconda release (e.g., MINICONDA_VER='4.0.5')
### BEGIN TEMP FIX https://bombora.atlassian.net/browse/DS-1777:
#if [[ ! -v MINICONDA_VER ]]; then
#    echo "MINICONDA_VER not set, setting ..."
#    MINICONDA_VER='latest'
#    echo "Set MINICONDA_VER to $MINICONDA_VER"
#fi
MINICONDA_VER='4.5.1.rc0'
### END TEMP FIX https://bombora.atlassian.net/browse/DS-1777:


## 0.2 Compute Miniconda version
MINICONDA_FULL_NAME="Miniconda$MINICONDA_VARIANT-$MINICONDA_VER-$OS_TYPE"
echo "Complete Miniconda version resolved to: $MINICONDA_FULL_NAME"

## 0.3 Set MD5 hash for check (if desired)
#expectedHash="b1b15a3436bb7de1da3ccc6e08c7a5df"

if [[ ! -v PROFILE_FILE ]]; then
    echo "PROFILE_FILE not set, setting ..."
    export PROFILE_FILE=/etc/profile.d/conda.sh
    echo "Set PROFILE_FILE to $PROFILE_FILE"
else
    mkdir -p $(dirname $PROFILE_FILE)
    touch $PROFILE_FILE
fi

if grep -ir "CONDA_BIN_PATH=$CONDA_BIN_PATH" $PROFILE_FILE  #/$HOME/.bashrc
    then
    echo "CONDA_BIN_PATH found in $PROFILE_FILE..."
    command -v conda >/dev/null && echo "conda command detected in $PATH"
    exit 0
fi

if [[ ! -v CONDA_INSTALL_PATH ]]; then
    echo "CONDA_INSTALL_PATH not set, setting ..."
    CONDA_INSTALL_PATH="/opt/conda"
    echo "Set CONDA_INSTALL_PATH to $CONDA_INSTALL_PATH"
fi

## If conda is already installed, skip installation
#if [[ -f "$PROFILE_DIR/conda.sh" ]]; then
#    echo "conda_config.sh found in /etc/profile.d/, Dataproc has installed conda previously. Skipping miniconda install!"
#    command -v conda >/dev/null && echo "conda command detected in $PATH"
#    exit 0
#fi

# 1. Setup Miniconda Install
## 1.1 Define Miniconda install directory
echo "Working directory: $PWD"
if [[ ! -v $PROJ_DIR ]]; then
    echo "No path argument specified, setting install directory as working directory: $PWD."
    PROJ_DIR=$PWD
fi

## 1.2 Setup Miniconda
cd $PROJ_DIR
MINICONDA_SCRIPT_PATH="$PROJ_DIR/$MINICONDA_FULL_NAME"
echo "Defined Miniconda script path: $MINICONDA_SCRIPT_PATH"

if [[ -f "$MINICONDA_SCRIPT_PATH" ]]; then
  echo "Found existing Miniconda script at: $MINICONDA_SCRIPT_PATH"
else
  echo "Downloading Miniconda script to: $MINICONDA_SCRIPT_PATH ..."
### BEGIN TEMP FIX https://bombora.atlassian.net/browse/DS-1777:
  #wget https://repo.continuum.io/miniconda/$MINICONDA_FULL_NAME -P "$PROJ_DIR"
  wget https://repo.anaconda.com/pkgs/misc/previews/miniconda/4.5.1/$MINICONDA_FULL_NAME -P "$PROJ_DIR"
### END TEMP FIX https://bombora.atlassian.net/browse/DS-1777:
  echo "Downloaded $MINICONDA_FULL_NAME!"
  ls -al $MINICONDA_SCRIPT_PATH
  chmod 755 $MINICONDA_SCRIPT_PATH
fi

## 1.3 #md5sum hash check of miniconda installer
if [[ -v expectedHash ]]; then
    md5Output=$(md5sum $MINICONDA_SCRIPT_PATH | awk '{print $1}')
    if [ "$expectedHash" != "$md5Output" ]; then
        echo "Unexpected md5sum $md5Output for $MINICONDA_FULL_NAME"
        exit 1
    fi
fi

# 2. Install conda
## 2.1 Via bootstrap
LOCAL_CONDA_PATH="$PROJ_DIR/miniconda"
if [[ ! -d $LOCAL_CONDA_PATH ]]; then
    #blow away old symlink / default Miniconda install
    rm -rf "$PROJ_DIR/miniconda"
    # Install Miniconda
    echo "Installing $MINICONDA_FULL_NAME to $CONDA_INSTALL_PATH..."
    bash $MINICONDA_SCRIPT_PATH -b -p $CONDA_INSTALL_PATH -f
    chmod 755 $CONDA_INSTALL_PATH
    #create symlink
    ln -sf $CONDA_INSTALL_PATH "$PROJ_DIR/miniconda"
    chmod 755 "$PROJ_DIR/miniconda"
else
    echo "Existing directory at path: $LOCAL_CONDA_PATH, skipping install!"
fi

## 2.2 Update PATH and conda...
echo "Setting environment variables..."
CONDA_BIN_PATH="$CONDA_INSTALL_PATH/bin"
export PATH="$CONDA_BIN_PATH:$PATH"
echo "Updated PATH: $PATH"
echo "And also HOME: $HOME"
hash -r
which conda
conda config --set always_yes true --set changeps1 false

# Useful printout for debugging any issues with conda
conda info -a

## 2.3 Update global profiles to add the miniconda location to PATH
echo "Updating global profiles to export miniconda bin location to PATH..."
if grep -ir "CONDA_BIN_PATH=$CONDA_BIN_PATH" $PROFILE_FILE  #/$HOME/.bashrc
    then
    echo "CONDA_BIN_PATH found in /etc/profile , skipping..."
else
    echo "Adding path definition to profiles..."
    echo "export CONDA_BIN_PATH=$CONDA_BIN_PATH" | tee -a $PROFILE_FILE #/etc/*bashrc /etc/profile
    echo 'export PATH=$CONDA_BIN_PATH:$PATH' | tee -a $PROFILE_FILE  #/etc/*bashrc /etc/profile

fi

echo "Finished bootstrapping via Miniconda, sourcing $PROFILE_FILE ..."
source $PROFILE_FILE

echo "Tip! If you're human, you might also consider installing useful conda packaging utilities in root env via..."
echo "conda install -q anaconda-client conda-build"
echo "Also, your newly-installed conda binary has been installed at $CONDA_BIN_PATH, so you might want to add it to your PATH if it isn't there already and ensure your init files set CONDA_BIN_PATH accordingly"
echo "Similarly, $PROFILE_FILE will need to be source-ed next time you log in to have access to conda, so ensure your init files call them"
