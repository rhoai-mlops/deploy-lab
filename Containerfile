FROM quay.io/modh/codeserver@sha256:b0544754e3bb77f5445b30ec503e91e454310a1a5fcb44866c501bb5cff955c1

USER root

ENV HELM_VERSION=3.17.2 \
    ROX_VERSION=4.7.0 \
    KUBELINTER_VERSION=0.7.2 \
    COSIGN_VERSION=2.4.3 \
    SYFT_VERSION=1.21.0 \
    KUBESEAL_VERSION=0.29.0 

# helm
RUN curl -skL -o /tmp/helm.tar.gz https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz && \
    tar -C /tmp -xzf /tmp/helm.tar.gz && \
    mv -v /tmp/linux-amd64/helm /usr/local/bin && \
    chmod -R 775 /usr/local/bin/helm && \
    rm -rf /tmp/linux-amd64

 # roxctl client
RUN curl -sL -o /usr/local/bin/roxctl https://mirror.openshift.com/pub/rhacs/assets/${ROX_VERSION}/bin/Linux/roxctl && \
    chmod +x /usr/local/bin/roxctl

# kube-linter
RUN curl -sL https://github.com/stackrox/kube-linter/releases/download/v${KUBELINTER_VERSION}/kube-linter-linux.tar.gz | tar -C /usr/local/bin -xzf - && \
    chmod +x /usr/local/bin/kube-linter

# cosign
RUN curl -skL -o /usr/local/bin/cosign https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-amd64 && \
    chmod -R 775 /usr/local/bin/cosign

# syft
RUN curl -sSfL https://raw.githubusercontent.com/anchore/syft/v${SYFT_VERSION}/install.sh | sh -s -- -b /usr/local/bin

# kubeseal
RUN curl -sL https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz | tar --no-same-owner -xzf - -C /usr/local/bin kubeseal && \
    chmod -R 755 /usr/local/bin/kubeseal

USER 1001

WORKDIR /opt/app-root/src