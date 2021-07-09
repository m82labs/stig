FROM alpine:3.14
ADD src/generate_configs.py /
RUN mkdir -p /opt/stig
RUN apk add --no-cache python3 py3-yaml
CMD ["python3","/generate_configs.py"]