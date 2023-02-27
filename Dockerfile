ARG NUCLIO_LABEL=1.3.22
ARG NUCLIO_ARCH=amd64
ARG NUCLIO_BASE_IMAGE=python:3.7-slim-bullseye
ARG NUCLIO_ONBUILD_IMAGE=quay.io/nuclio/handler-builder-python-onbuild:${NUCLIO_LABEL}-${NUCLIO_ARCH}

# Supplies processor uhttpc, used for healthcheck
FROM nuclio/uhttpc:0.0.1-amd64 as uhttpc

# Supplies processor binary, wrapper
FROM ${NUCLIO_ONBUILD_IMAGE} as processor

# From the base image
FROM ${NUCLIO_BASE_IMAGE}

# Copy required objects from the suppliers
COPY --from=processor /home/nuclio/bin/processor /usr/local/bin/processor
COPY --from=processor /home/nuclio/bin/py /opt/nuclio/
COPY --from=uhttpc /home/nuclio/bin/uhttpc /usr/local/bin/uhttpc

RUN apt-get update && apt-get install ffmpeg libsm6 libxext6  -y

RUN whoami
# Create a non-root user
RUN useradd --create-home appuser
USER appuser

RUN pip install nuclio-sdk msgpack --no-index --find-links /opt/nuclio/whl
RUN ls -al /opt/nuclio/
RUN pip install Pillow
RUN pip install torchvision
RUN pip install ultralytics

USER root
RUN whoami
# Readiness probe
HEALTHCHECK --interval=1s --timeout=3s CMD /usr/local/bin/uhttpc --url http://127.0.0.1:8082/ready || exit 1

# USER CONTENT

USER appuser
RUN python -c "import PIL"
USER root
# Copy the model file to the /opt/nuclio directory
COPY best.pt /opt/nuclio
COPY my_requirements.txt /opt/nuclio/

RUN ls -al /opt/nuclio/requirements

ADD ./main.py /opt/nuclio
ADD ./function.yaml /etc/nuclio/config/processor/processor.yaml
# END OF USER CONTENT
# Run processor with configuration and platform configuration
CMD [ "processor" ]
