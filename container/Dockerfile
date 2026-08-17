ARG FREESURFER_BUILD_IMAGE=ubuntu:22.04
ARG SCILPY_BASE_IMAGE=scilus/scilpy:2.1.0

# Create a stage to build the freesurfer image (only essential scripts).
FROM $FREESURFER_BUILD_IMAGE AS build_freesurfer

ENV LANG=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# Install packages needed for build
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      file \
      git \
      upx \
      wget && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ARG PYTHON_VERSION=3.10

# Fetch install script in docker.
RUN mkdir /install
COPY ./install_freesurfer.sh /install/
RUN ["chmod", "+x", "/install/install_freesurfer.sh"]
SHELL ["/bin/bash", "--login", "-c"]

ARG FREESURFER_URL=default

RUN /install/install_freesurfer.sh /opt --upx --url $FREESURFER_URL
RUN rm /opt/freesurfer/bin/fspython
RUN rm -R /install

# Main stage from scilpy base image.
FROM $SCILPY_BASE_IMAGE AS runtime

ENV LANG=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages for freesurfer to dry_run
RUN apt-get update && apt-get install -y --no-install-recommends \
      bc \
      gawk \
      libgomp1 \
      libquadmath0 \
      libglu1-mesa \
      libxt6 \
      libxmu6 \
      libgl1 \
      freeglut3-dev \
      python3.10 \
      wget \
      curl \
      time \
      tcsh \
      parallel && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo 'will cite' | parallel --citation 1> /dev/null 2> /dev/null &

# Add FreeSurfer and python Environment variables
# DO_NOT_SEARCH_FS_LICENSE_IN_FREESURFER_HOME=true deactivates the search for FS_LICENSE in FREESURFER_HOME
ENV PYTHONPATH=""
ENV OS=Linux \
    FS_OVERRIDE=0 \
    FIX_VERTEX_AREA="" \
    SUBJECTS_DIR=/opt/freesurfer/subjects \
    FSF_OUTPUT_FORMAT=nii.gz \
    FREESURFER_HOME=/opt/freesurfer \
    PYTHONUNBUFFERED=0 \
    MPLCONFIGDIR=/tmp \
    PATH=/venv/bin:/opt/freesurfer/bin:$PATH \
    PYTHONPATH=opt/freesurfer/python/packages:$PYTHONPATH \
    MPLCONFIGDIR=/tmp/matplotlib-config \
    DO_NOT_SEARCH_FS_LICENSE_IN_FREESURFER_HOME="true"

# generate_atlas_FS_BN_GL_SF_v5.sh invokes python3.7 explicitly; point it at the
# venv's python (with dipy/nibabel/scilpy already installed) rather than a real
# Python 3.7, which scilpy 2.1.0 (requires >=3.9) couldn't run anyway.
RUN ln -s "$(command -v python3)" /usr/local/bin/python3.7

COPY --from=build_freesurfer /opt/freesurfer /opt/freesurfer

RUN wget -O /FS_BN_GL_SF_utils.tar "https://www.dropbox.com/s/zzptxby9pf5lpih/FS_BN_GL_SF_utils.tar?dl=0?download=1"
RUN wget -O /opt/freesurfer/.license "https://www.dropbox.com/s/zs4k3bcfxderj58/license.txt?dl=0"

RUN ["tar", "xf", "/FS_BN_GL_SF_utils.tar"]
RUN ["rm", "/FS_BN_GL_SF_utils.tar"]

# generate_atlas_FS_BN_GL_SF_v5.sh still calls scilpy with a CLI that scilpy
# 2.1.0 removed: `-v <vol> <id>` for scil_combine_labels.py now collides with
# the `-v/--verbosity` flag, and `--label_to_dilate` was renamed (plural) in
# scil_dilate_labels.py. Patch both so the atlas outputs actually get built.
RUN sed -i \
      -e 's/ -v / --volume_ids /g' \
      -e 's/--label_to_dilate/--labels_to_dilate/g' \
      /FS_BN_GL_SF_utils/freesurfer_utils/generate_atlas_FS_BN_GL_SF_v5.sh

RUN mkdir -p /Yale_atlas_utils && \
    wget -O /Yale_atlas_utils/YBA_696_LH_fsaverage.annot "https://raw.githubusercontent.com/YaleBrainAtlas/YaleBrainAtlas/master/data/YBA_696parcels/YBA_696_LH_fsaverage.annot" && \
    wget -O /Yale_atlas_utils/YBA_696_RH_fsaverage.annot "https://raw.githubusercontent.com/YaleBrainAtlas/YaleBrainAtlas/master/data/YBA_696parcels/YBA_696_RH_fsaverage.annot" && \
    wget -O /Yale_atlas_utils/YBA_696_LUT.txt "https://raw.githubusercontent.com/YaleBrainAtlas/YaleBrainAtlas/master/data/YBA_696parcels/YBA_696_LUT.txt"