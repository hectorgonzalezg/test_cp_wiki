FROM debian:bullseye
WORKDIR /usr/src/app
RUN apt-get update && apt-get install -y \
    zip python3 python3-pip gcc musl-dev libffi-dev wget unzip curl git python3-dateutil jq -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/
RUN wget --quiet https://releases.hashicorp.com/terraform/0.13.6/terraform_0.13.6_linux_amd64.zip \
  && unzip terraform_0.13.6_linux_amd64.zip \
  && mv terraform /usr/bin \
  && rm terraform_0.13.6_linux_amd64.zip
# If using EKS
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
&& unzip awscliv2.zip \
&& ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update \
&& rm -rf awscliv2.zip
RUN useradd -m -u 1000 jenkins
USER 1000
ENTRYPOINT ["/bin/sh","-c"]