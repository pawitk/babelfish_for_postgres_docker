FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV INSTALLATION_PATH=/usr/local/pgsql
ENV EXTENSIONS_SOURCE_CODE_PATH="$HOME/babelfish_extensions"
ENV PG_CONFIG=$INSTALLATION_PATH/bin/pg_config
ENV PG_SRC=$HOME/postgresql_modified_for_babelfish
ENV cmake=/usr/local/bin/cmake

COPY ./postgresql_modified_for_babelfish $PG_SRC
COPY ./babelfish_extensions $EXTENSIONS_SOURCE_CODE_PATH

RUN apt update && apt install -y build-essential flex libxml2-dev libxslt-dev libssl-dev
RUN apt update && apt install -y libreadline-dev zlib1g-dev libldap2-dev libpam0g-dev bison
RUN apt update && apt install -y uuid uuid-dev lld pkg-config libossp-uuid-dev gnulib
RUN apt update && apt install -y libxml2-utils xsltproc icu-devtools libicu66 libicu-dev gawk
RUN apt update && apt install -y openjdk-8-jre openssl python-dev libpq-dev pkgconf unzip libutfcpp-dev
RUN apt update && apt install -y git-core
RUN apt update && apt install -y python2

RUN ldconfig -v

# Install CMake
RUN curl -L https://github.com/Kitware/CMake/releases/download/v3.20.6/cmake-3.20.6-linux-x86_64.sh --output /opt/cmake-3.20.6-linux-x86_64.sh
RUN chmod +x /opt/cmake-3.20.6-linux-x86_64.sh 
RUN /opt/cmake-3.20.6-linux-x86_64.sh --prefix=/usr/local --skip-license

# Install Antlr4
RUN curl https://www.antlr.org/download/antlr4-cpp-runtime-4.9.2-source.zip --output /opt/antlr4-cpp-runtime-4.9.2-source.zip 
RUN unzip -d /opt/antlr4 /opt/antlr4-cpp-runtime-4.9.2-source.zip
RUN mkdir /opt/antlr4/build 
RUN cd /opt/antlr4/build && \
    cmake .. -DANTLR_JAR_LOCATION="$EXTENSIONS_SOURCE_CODE_PATH/contrib/babelfishpg_tsql/antlr/thirdparty/antlr/antlr-4.9.2-complete.jar" -DCMAKE_INSTALL_PREFIX=/usr/local -DWITH_DEMO=True \
    && make && make install

RUN mkdir "$INSTALLATION_PATH"

RUN cd $PG_SRC && ./configure CFLAGS="${CFLAGS:--Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic}" \
  --prefix=$INSTALLATION_PATH \
  --enable-thread-safety \
  --enable-cassert \
  --enable-debug \
  --with-ldap \
  --with-python \
  --with-libxml \
  --with-pam \
  --with-uuid=ossp \
  --enable-nls \
  --with-libxslt \
  --with-icu \
  --with-python PYTHON=/usr/bin/python2 \
  --with-extra-version=" Babelfish for PostgreSQL" \
  --without-python \
  && make \
  && cd contrib  \
  && make \
  && cd .. \
  && make install \
  && cd contrib \
  && make install 

RUN cp /usr/local/lib/libantlr4-runtime.so.4.9.2 "$INSTALLATION_PATH/lib"

RUN cd $EXTENSIONS_SOURCE_CODE_PATH/contrib/babelfishpg_money && make && make install

RUN cd $EXTENSIONS_SOURCE_CODE_PATH/contrib/babelfishpg_common && make && make install

RUN cd $EXTENSIONS_SOURCE_CODE_PATH/contrib/babelfishpg_tds && make && make install

RUN cd $EXTENSIONS_SOURCE_CODE_PATH/contrib/babelfishpg_tsql && make && make install

EXPOSE 5432
EXPOSE 1433

CMD ['su - postgres -c "/usr/local/pgsql/bin/postgres"]