FROM mambaorg/micromamba

COPY --chown=$MAMBA_USER:$MAMBA_USER env.yml /tmp/environment.yml

RUN micromamba install -y -n base -f /tmp/environment.yml \
  && micromamba clean --all --yes

ADD deseq2_normalize.R /usr/local/bin/deseq2_normalize.R

