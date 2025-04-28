# MSD-LIVE BLANK Notebook


This repo contains the Dockerfile to build the notebook image as well as the notebooks
used in the MSD-LIVE deployment. It will rebuild the image and redeploy the notebooks
whenever changes are pushed to the main branch.

**The data folder is too big, so we are not checking this into github. You will have
to pull from s3 (instructions below) if you want to test locally**



## Developing the project notebook container:
1. Your Dockerfile needs to:
   1. Extend one of our base images:
      ```
      FROM ghcr.io/msd-live/jupyter/python-notebook:latest 
      FROM ghcr.io/msd-live/jupyter/r-notebook:latest 
      FROM ghcr.io/msd-live/jupyter/julia-notebook:latest 
      FROM ghcr.io/msd-live/jupyter/base-panel-jupyter-notebook:latest

      ```
   1. Copy in the notebooks and any other files needed in order to run. When the container starts everything in the /home/jovyan folder will be copied to the current user's home folder
      ```
      COPY notebooks /home/jovyan/notebooks
      ```
1. Containers extending one of these base images will have a `DATA_DIR` environment variable set and the value will be the path to the read-only staged input data, or `/data`. There will also be a symbolic link created in the user's home folder named 'data' that points to `/data` when the container starts. 
1. Notebook implementations should look for the DATA_DIR environment variable and if set use that path as the input data used instead of downloading it.  For an example of this see [this example](https://github.com/MSD-LIVE/jupyter-notebook-cerf/blob/f5e6753ef524f5b8bfd64e9dac89c3c59a1aa457/notebooks/quickstarter.ipynb#L121)
1. Some notebook libraries expect data to be located within the package. For this, feel free to add a symbolic link from `/data` to the package via the Dockerfile. Here is an example of doing that:
   ```
   RUN rm -rf /opt/conda/lib/python3.11/site-packages/cerf/data
   RUN ln -s /data /opt/conda/lib/python3.11/site-packages/cerf/data
   ```

## Project notebook Docker Images 
1. Your repo's dev branch builds the image and tags it with 'dev', the main branch tags the image with 'latest'
1. After the initial build go to MSD-LIVE's [packages in github](https://github.com/orgs/MSD-LIVE/packages) click on your package, click on settings to the right, scroll to the bottom of the settings page and make sure the 'package visibility' is set to public (the notebook will fail to launch from MSD-LIVE's services if not set)


## Notebook customizations

Here are some ways to add specific behaviors for notebook containers. Note these are advanced use cases and not necessary for most deployments.

1. Project notebook deployments can include a plugin to implement custom behaviors such as copying the input folder to the user's home folder because it cannot be read-only. [Here](https://github.com/MSD-LIVE/jupyter-notebook-statemodify) is an exmple of this behavior but is essentially these steps:
   1. Dockerfile needs to copy in and install the extension:
   ```
   COPY msdlive_hooks /srv/jupyter/extensions/msdlive_hooks
   RUN pip install /srv/jupyter/extensions/msdlive_hooks
   ```
   1. [setup.py](https://github.com/MSD-LIVE/jupyter-notebook-statemodify/blob/main/msdlive_hooks/setup.py) uses entry_points so this plugin is discoverable to MSD-LIVE's
   1. [The implementation](https://github.com/MSD-LIVE/jupyter-notebook-statemodify/blob/main/msdlive_hooks/msdlive_hooks/activate.py) removes the 'data' symlink from the user's home and and copies it in from /data instead
1. Deployments can include a service to run within the notebook container. See [this](https://github.com/MSD-LIVE/jupyter-notebook-rgcam) example of how a database (basex) is started via the container's entry point.
1. Deployments can include a service proxied by Jupyter in order for it to have authenticated web access. See proxy [docs here](https://jupyter-server-proxy.readthedocs.io/en/latest/index.html) and MSD-LIVE notes about it's use [here](https://github.com/MSD-LIVE/base-jupyter-notebook/blob/main/jupyter-server-proxy/README.md)




## Testing the notebook locally

1. Get the data (requires .aws/credentials to be set or use of aws access tokens [see next section on how to get and use])

   ```bash
   # make sure you are in the jupyter-notebook-<<blank>> folder
   mkdir data
   cd data
   aws s3 cp s3://<<blank>>-notebook-bucket/data . --recursive

   ```

2. Start the notebook via docker compose
   ```bash
   # make sure you are in the jupyter-notebook-<<blank>> folder
   cd ..
   docker compose up
   ```
