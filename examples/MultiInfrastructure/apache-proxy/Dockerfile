FROM docker.io/httpd:2.4

# Enable required modules
RUN sed -i \
    -e 's/^#\(LoadModule .*mod_proxy.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_proxy_http.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_ssl.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_socache_shmcb.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_rewrite.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_headers.so\)/\1/' \
    conf/httpd.conf

# Include virtual hosts configuration
RUN echo "Include conf/vhosts/*.conf" >> conf/httpd.conf

# Copy SSL certificates
COPY certs/*.crt /usr/local/apache2/conf/certs/
COPY certs/*.key /usr/local/apache2/conf/certs/

# Copy virtual host configurations
COPY apache-proxy/vhosts/ /usr/local/apache2/conf/vhosts/
