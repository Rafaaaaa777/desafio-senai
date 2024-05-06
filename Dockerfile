# STAGE 1
FROM alpine:latest as builder

# Atualizando pacotes
RUN apk update && \
    apk add wget unzip curl python3.9 py3-pip

# Instalar Terraform
RUN wget https://releases.hashicorp.com/terraform/1.8.2/terraform_1.8.2_linux_amd64.zip && \
    unzip terraform_1.8.2_linux_amd64.zip && \
    mv terraform /usr/local/bin/

# Instalar o Python
RUN apk add python3.9 py3-pip

# Instalar awscli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install -i /usr/local/aws-cli -b /usr/local/bin

WORKDIR /work/
COPY app/ .

# Instalar os requisitos mínimos (requirements.txt)
RUN python3 -m pip install -r requirements.txt

# STAGE 2
FROM alpine:latest

WORKDIR /work

COPY --from=builder /usr/local/bin/terraform /usr/local/bin/terraform 
COPY --from=builder /usr/local/bin/aws /usr/local/bin/aws
COPY --from=builder /work /work

# Definir variáveis ​​de ambiente
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_DEFAULT_REGION

RUN echo "[default]" >> /root/.aws/credentials && \
    echo "aws_access_key_id = $AWS_ACCESS_KEY_ID" >> /root/.aws/credentials && \
    echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" >> /root/.aws/credentials

RUN apk update && \
    apk add python3.9 py3-pip && \
    python3 -m pip install -r /work/requirements.txt

EXPOSE 8080

# Rodar a aplicação
CMD ["python3", "app.py"]
