#!/bin/bash

if [ -f "root/miniconda3/etc/profile.d/conda.sh" ] ; then
    . "root/miniconda3/etc/profile.d/conda.sh"
    CONDA_CHANGEPS1=false conda activate invokeai
fi

if [ -f "/InvokeAI/setup.py" ] ; then
    git config --global --add safe.directory /InvokeAI
    cd /InvokeAI/
else
    echo "Cloning Git Repo in to Local Folder..."
    git config --global --add safe.directory /InvokeAI
    git clone https://github.com/invoke-ai/InvokeAI.git
    cd /InvokeAI/
    cp configs/models.yaml.example configs/models.yaml
fi

if [[ $(lshw -C display | grep -i vendor) = *AMD* ]] && [[ $(lshw -C display | grep -i vendor) != *NVIDIA* ]] && [ ! -f "environment.yml" ] ; then
    echo "AMD GPU Found"
    cp environments-and-requirements/environment-lin-amd.yml environment.yml
elif [[ $(lshw -C display | grep -i vendor) = *NVIDIA* ]] && [ ! -f "environment.yml" ] ; then
    echo "Nvidia GPU Found"
    cp environments-and-requirements/environment-lin-cuda.yml environment.yml
fi

echo "Checking if The Git Repo Has Changed...."
git fetch
UPSTREAM=${1:-'@{u}'}
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "$UPSTREAM")
BASE=$(git merge-base @ "$UPSTREAM")

if [ $LOCAL = $REMOTE ]; then
    echo "Local Files Are Up to Date"
elif [ $LOCAL = $BASE ]; then
    echo "Updates Found, Updating the local Files...."
    git config pull.rebase false
    git pull
fi

current=$(date +%s)
last_modified_envcuda=$(stat -c "%Y" "environments-and-requirements/environment-lin-cuda.yml")
last_modified_envamd=$(stat -c "%Y" "environments-and-requirements/environment-lin-amd.yml")
last_modified_pre=$(stat -c "%Y" "scripts/preload_models.py")

if { conda env list | grep 'invokeai'; }  >/dev/null 2>&1 && [ $(($current-$last_modified_envamd)) -lt 60 ] && [[ $(lshw -C display | grep -i vendor) = *AMD* ]] && [[ $(lshw -C display | grep -i vendor) != *NVIDIA* ]] ; then
    cp environments-and-requirements/environment-lin-amd.yml environment.yml
    echo "Updates Found, Updating Conda Environment...."
    conda env update -f environment.yml --prune
    echo "Cleaning up Temporary files...."
    conda clean --all -y
elif { conda env list | grep 'invokeai'; }  >/dev/null 2>&1 && [ $(($current-$last_modified_envcuda)) -lt 60 ] && [[ $(lshw -C display | grep -i vendor) = *NVIDIA* ]] ; then
    cp environments-and-requirements/environment-lin-cuda.yml environment.yml
    echo "Updates Found, Updating Conda Environment...."
    conda env update -f environment.yml --prune
    echo "Cleaning up Temporary files...."
    conda clean --all -y
fi

if { conda env list | grep 'invokeai'; }  >/dev/null 2>&1 && [ $(($current-$last_modified_pre)) -lt 60 ] ; then 
    echo "Updates Found, Updating Model Preload...."
    conda activate invokeai
    python scripts/preload_models.py --no-interactive
fi

if { conda env list | grep 'invokeai'; }  >/dev/null 2>&1 ; then
    conda activate invokeai
else
    echo "Creating Conda Environment invokeai...."
    conda env create -f environment.yml
    conda activate invokeai
    echo "Preloading Important Models/Weights...."
    python scripts/preload_models.py --no-interactive
    echo "Cleaning up Temporary files...."
    conda clean --all -y 
fi

if [ ! -f "/root/.invokeai" ] ; then
    echo '--web --host=0.0.0.0' > /root/.invokeai
    echo "Loading InvokeAI WebUi...."
    python scripts/invoke.py
else
    echo "Loading InvokeAI WebUi...."
    python scripts/invoke.py
fi