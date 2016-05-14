FROM gitlab/dind:latest
MAINTAINER Firef0x

ENV GITLAB_CI_MULTI_RUNNER_VERSION=1.1.3 \
    GITLAB_CI_MULTI_RUNNER_USER=gitlab_ci_multi_runner \
    GITLAB_CI_MULTI_RUNNER_HOME_DIR="/home/gitlab_ci_multi_runner"
ENV GITLAB_CI_MULTI_RUNNER_DATA_DIR="${GITLAB_CI_MULTI_RUNNER_HOME_DIR}/data"
ENV DOCKER_DAEMON_ARGS="--insecure-registry 14.23.118.162:3005"
ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 6.1.0

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv E1DD270288B4E6030699E45FA1715D88E1DF1F24 \
 && echo 'APT::Install-Recommends 0;' >> /etc/apt/apt.conf.d/01norecommends \
 && echo 'APT::Install-Suggests 0;' >> /etc/apt/apt.conf.d/01norecommends \
 && echo "deb http://ppa.launchpad.net/git-core/ppa/ubuntu trusty main" >> /etc/apt/sources.list \
# && sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list \
 && sed -i 's/^deb-src/# deb-src/g' /etc/apt/sources.list \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
      vim.tiny wget sudo net-tools ca-certificates unzip git-core openssh-client curl libapparmor1 \
 && wget -O /usr/local/bin/gitlab-ci-multi-runner \
      https://gitlab-ci-multi-runner-downloads.s3.amazonaws.com/v${GITLAB_CI_MULTI_RUNNER_VERSION}/binaries/gitlab-ci-multi-runner-linux-amd64 \
 && chmod 0755 /usr/local/bin/gitlab-ci-multi-runner \
 && adduser --disabled-login --gecos 'GitLab CI Runner' ${GITLAB_CI_MULTI_RUNNER_USER} \
 && sudo -HEu ${GITLAB_CI_MULTI_RUNNER_USER} ln -sf ${GITLAB_CI_MULTI_RUNNER_DATA_DIR}/.ssh ${GITLAB_CI_MULTI_RUNNER_HOME_DIR}/.ssh \
 && rm -rf /var/lib/apt/lists/*

RUN set -ex \
 && for key in \
 9554F04D7259F04124DE6B476D5A82AC7E37093B \
 94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
 0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
 FD3A5288F042B6850C66B31F09FE44734EB7990E \
 71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
 DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
 B9AE9905FFD7803F25714661B63B535A4C206CA9 \
 C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
 ; do \
 gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
 done

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
 && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
 && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
 && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
 && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
 && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt

RUN npm install -g nrm
 && nrm use taobao

COPY entrypoint.sh /sbin/entrypoint.sh
RUN sed -i 's/to_be_filled/${DOCKER_DAEMON_ARGS}/' /sbin/entrypoint.sh \
 && chmod 755 /sbin/entrypoint.sh

VOLUME ["${GITLAB_CI_MULTI_RUNNER_DATA_DIR}"]
WORKDIR "${GITLAB_CI_MULTI_RUNNER_HOME_DIR}"
ENTRYPOINT ["/sbin/entrypoint.sh"]
