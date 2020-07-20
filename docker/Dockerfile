FROM nfcore/base
LABEL authors="vlad@lifebit.ai" \
      description="Docker image containing base requirements for Participant data pipeline"

COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a
ENV PATH /opt/conda/envs/participant-data-pipeline/bin:$PATH
