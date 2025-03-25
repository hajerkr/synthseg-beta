# --- FSL Stage ---
FROM condaforge/miniforge3 AS fsl-build
LABEL maintainer="FSL development team"
ENV PATH="/opt/conda/bin:${PATH}"
ENV DEBIAN_FRONTEND=non-interactive
# Set FSLDIR environment variable
ENV FSLDIR="/opt/conda"

# Store FSL public conda channel
ENV FSL_CONDA_CHANNEL="https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/public"
COPY entrypoint /entrypoint
RUN chmod +x /entrypoint
RUN /opt/conda/bin/conda install -n base -c conda-forge tini
RUN /opt/conda/bin/conda install -n base -c $FSL_CONDA_CHANNEL fsl-flirt fsl-miscvis -c conda-forge


# Configure entrypoint
#RUN chmod a+x $FLYWHEEL/run.py

# --- Build Stage for FreeSurfer ---
#FROM ubuntu:20.04 AS builder
FROM python:3.10-slim AS freesurfer-builder

ENV FREESURFER_HOME=/opt/freesurfer
ENV DEBIAN_FRONTEND=non-interactive
ARG FREESURFER_VERSION=7.4.1

RUN apt-get update && apt-get install -y \
    wget tar unzip perl build-essential libsqlite3-dev python3 python3-pip imagemagick && rm -rf /var/lib/apt/lists/*

# Install FreeSurfer (only required parts)
RUN wget -vO- https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/${FREESURFER_VERSION}/freesurfer-linux-ubuntu22_amd64-${FREESURFER_VERSION}.tar.gz | tar -xz -C /opt
RUN echo "source $FREESURFER_HOME/SetUpFreeSurfer.sh" >> ~/.bashrc

COPY includes.txt .

RUN mkdir -p /freesurfer

RUN while IFS= read -r file; do \
    mkdir -p /freesurfer/$(dirname "$file") && \
    mv -v /opt/"$file" /freesurfer/"$file"; \
    done < includes.txt

#ENV FS_LICENSE='/opt/freesurfer/license.txt'
#ENV PATH='/opt/freesurfer/bin:/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/freesurfer/fsfast/bin:/opt/freesurfer/tktools:/opt/freesurfer/mni/bin:/sbin:/bin:/opt/ants/bin'
# 
# 
# RUN apt-get update && apt-get install -y \
#     wget \
#     tar \
#     tcsh \
#     perl \
#     build-essential \
#     libsqlite3-dev && rm -rf /var/lib/apt/lists/*

# ENV FREESURFER_HOME=/opt/freesurfer

# # Download and install FreeSurfer
# RUN wget -vO /tmp/freesurfer.tar.gz https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/${FREESURFER_VERSION}/freesurfer-linux-ubuntu22_amd64-${FREESURFER_VERSION}.tar.gz
# RUN tar zxvf /tmp/freesurfer.tar.gz -C /opt



# --- Final stage ---
FROM python:3.10-slim

# Copy FreeSurfer-related files from the first stage
# FROM ubuntu:20.04
#COPY --from=freesurfer-builder /opt/freesurfer/bin/mri_synthseg /usr/local/bin/ #commented 25/03
#COPY --from=freesurfer-builder /opt/freesurfer/lib /usr/local/lib #commented 25/03
#COPY --from=freesurfer-builder /usr/bin/convert /usr/bin/   #commented 25/03
COPY --from=freesurfer-builder /freesurfer/ /opt/freesurfer/

# Copy FSL-related files from the second stage
COPY --from=fsl-build /opt/conda /opt/conda
    
ENV FLYWHEEL="/flywheel/v0"
WORKDIR ${FLYWHEEL}

# FreeSurfer environment variables
ENV FREESURFER_HOME=/opt/freesurfer
ENV FS_LICENSE='/opt/freesurfer/license.txt'
ENV PATH='/opt/freesurfer/bin:/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/freesurfer/fsfast/bin:/opt/freesurfer/tktools:/opt/freesurfer/mni/bin:/sbin:/bin:/opt/ants/bin'

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    tcsh \
    perl \
    build-essential \
    libsqlite3-dev && rm -rf /var/lib/apt/lists/*

RUN pip3 install flywheel-gear-toolkit && \
pip3 install flywheel-sdk==19.3.0 && \
pip3 install jsonschema && \
pip3 install pandas importlib-metadata

# Install Python dependencies
COPY requirements.txt $FLYWHEEL/
RUN pip3 install --no-cache-dir -r $FLYWHEEL/requirements.txt
COPY ./ $FLYWHEEL/

ENTRYPOINT ["python","/flywheel/v0/run.py"]
