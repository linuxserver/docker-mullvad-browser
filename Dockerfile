FROM ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy

# set version label
ARG BUILD_DATE
ARG VERSION
ARG MULLVAD_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thespad"

# title
ENV TITLE=Mullvad-Browser
ENV MULLVAD_RELEASE_GPG_KEY="A1198702FC3E0A09A9AE5B75D5A1D4F266DE8DDF"
ENV TORPROJECT_RELEASE_GPG_KEY="EF6E286DDA85EA2A4BA7DE684E2C6E8793298290"

RUN \
  echo "**** install packages ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    fontconfig \
    gnupg \
    ifupdown \
    iproute2 \
    iptables \
    libdbus-glib-1-2 \
    libgtk-3-0 \
    net-tools \
    openresolv \
    wireguard \
    xz-utils && \
  echo "**** install mullvad browser ****" && \
  mkdir -p /app && \
  if [ -z ${MULLVAD_VERSION+x} ]; then \
    MULLVAD_VERSION=$(curl -sX GET "https://api.github.com/repos/mullvad/mullvad-browser/releases/latest" \
    | jq -r .name | awk -F ' ' '{print $3}'); \
  fi && \
  curl -s -o \
    /tmp/mullvad.tar.xz -L \
    "https://cdn.mullvad.net/browser/${MULLVAD_VERSION}/mullvad-browser-linux-x86_64-${MULLVAD_VERSION}.tar.xz" && \
  curl -s -o \
    /tmp/mullvad.tar.xz.asc -L \
    "https://cdn.mullvad.net/browser/${MULLVAD_VERSION}/mullvad-browser-linux-x86_64-${MULLVAD_VERSION}.tar.xz.asc" && \
  export GNUPGHOME="$(mktemp -d)" && \
  gpg --batch -q --recv-keys "$TORPROJECT_RELEASE_GPG_KEY" && \
  gpg --batch -q --recv-keys "$MULLVAD_RELEASE_GPG_KEY" && \
  if ! gpg --batch -q --verify "/tmp/mullvad.tar.xz.asc" "/tmp/mullvad.tar.xz"; then \
    echo "File signature mismatch"; \
    exit 1; \
  fi && \
  tar xf \
    /tmp/mullvad.tar.xz -C \
    /app --strip-components=1 && \
  mkdir /app/Data && \
  chmod 777 /app/Data && \
  find /app -perm 700 -exec chmod 755 {} + && \
  find /app -perm 600 -exec chmod 644 {} + && \
  sed -i 's|</applications>|  <application title="Mullvad Browser" type="normal">\n    <maximized>yes</maximized>\n  </application>\n</applications>|' /etc/xdg/openbox/rc.xml && \
  echo "**** cleanup ****" && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# add local files
COPY /root /

# ports and volumes
EXPOSE 3000 3001

VOLUME /config
