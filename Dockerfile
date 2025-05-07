
FROM ghcr.io/msd-live/jupyter/r-notebook:latest AS gcam_dev
RUN git clone --depth 1 --branch gcam-v7.1 https://github.com/JGCRI/gcam-core.git /home/jovyan/gcam-core
RUN cd /home/jovyan/gcam-core && \
    git submodule update --init cvs/objects/climate/source/hector
RUN git clone --depth 1 --branch gcam-v7.1 https://github.com/JGCRI/gcamwrapper.git /home/jovyan/gcamwrapper
RUN conda install -y tbb-devel=2020.2 libboost-headers
RUN sed -i 's/task\* next_offloaded/tbb::task* next_offloaded/' /opt/conda/include/tbb/task.h
RUN cd /opt/conda/include && \
    wget https://gitlab.com/libeigen/eigen/-/archive/3.4.0/eigen-3.4.0.tar.gz -O - | \
    tar -xz
RUN wget https://github.com/JGCRI/modelinterface/releases/download/v5.4/jars.zip && \
    unzip jars.zip -d /opt/conda/lib/ && \
    rm jars.zip
ENV CXX='x86_64-conda-linux-gnu-g++ -fPIC' \
    EIGEN_INCLUDE=/opt/conda/include/eigen-3.4.0 \
    BOOST_INCLUDE=/opt/conda/include \
    BOOST_LIB=/opt/conda/lib \
    TBB_INCLUDE=/opt/conda/include \
    TBB_LIB=/opt/conda/lib \
    JARS_LIB=/opt/conda/lib/jars/* \
    JAVA_INCLUDE=/opt/conda/lib/jvm/include \
    JAVA_LIB=/opt/conda/lib/jvm/lib/server \
    CXXEXTRA=-fPIC \
    CCEXTRA=-fPIC \
    HAVE_JAVA=0
RUN sed -i 's/HAVE_JAVA = 1/HAVE_JAVA = 0/' /home/jovyan/gcam-core/cvs/objects/build/linux/configure.gcam
#USER root
RUN cd /home/jovyan/gcam-core && \
    make -j 4 gcam
ENV GCAM_INCLUDE=/home/jovyan/gcam-core/cvs/objects \
    GCAM_LIB=/home/jovyan/gcam-core/cvs/objects/build/linux


FROM gcam_dev AS gcamwrapper_r_dev
RUN cd /home/jovyan/gcamwrapper && \
    Rscript -e "devtools::install_deps()"
RUN Rscript -e "devtools::install_cran('ggplot2')"
RUN cd /home/jovyan/gcamwrapper && \
    Rscript -e "devtools::install()"

FROM gcam_dev AS gcamwrapper_py_dev
RUN conda install libboost-python=1.85.0
RUN sed -i "s/, 'tbbmalloc_proxy'//" /home/jovyan/gcamwrapper/setup.py
ENV CC='x86_64-conda-linux-gnu-g++'
RUN cd /home/jovyan/gcamwrapper && \
    pip install .

FROM ghcr.io/msd-live/jupyter/r-notebook:latest AS gcamwrapper_deploy
RUN conda install -y tbb=2020.2 libboost-python=1.85.0 pandas
RUN pip install matplotlib
COPY --from=gcamwrapper_r_dev /opt/conda/lib/R/library /opt/conda/lib/R/library
COPY --from=gcamwrapper_py_dev /opt/conda/lib/python3.11/site-packages/gcam*.so /opt/conda/lib/python3.11/site-packages/
COPY --from=gcamwrapper_py_dev /opt/conda/lib/python3.11/site-packages/gcamwrapper /opt/conda/lib/python3.11/site-packages/gcamwrapper
COPY --from=gcamwrapper_py_dev /opt/conda/lib/python3.11/site-packages/gcamwrapper-0.1.0.dist-info /opt/conda/lib/python3.11/site-packages/gcamwrapper-0.1.0.dist-info
RUN mkdir -p /data && ln -s /data $HOME/data
COPY notebooks /home/jovyan/notebooks

