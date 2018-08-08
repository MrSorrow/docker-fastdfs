FROM centos:7.4.1708
RUN yum install gcc gcc-c++ make automake autoconf libtool pcre pcre-devel zlib zlib-devel openssl-devel tar -y
MAINTAINER coffeecoder
ADD soft /usr/local/src/
WORKDIR /usr/local/src/
# install libfastcommon
RUN tar -zxf libfastcommon-1.0.38.tar.gz && \
	rm -f libfastcommon-1.0.38.tar.gz && \
	cd libfastcommon-1.0.38 && \
	./make.sh && \
	./make.sh install && \
	# install fastdfs
	cd /usr/local/src/ && \
	tar -zxf fastdfs-5.11.tar.gz && \
	rm -f fastdfs-5.11.tar.gz && \
	cd fastdfs-5.11 && \
	./make.sh && \
	./make.sh install && \
	cd .. && \
    # copy config file
	rm -rf /etc/fdfs/* && \
	mv /usr/local/src/tracker.conf /etc/fdfs/ && \
	mv /usr/local/src/storage.conf /etc/fdfs/ && \
	mv /usr/local/src/client.conf /etc/fdfs/ && \
	mkdir -p /fastdfs/tracker && \
	mkdir -p /fastdfs/storage && \
	mkdir -p /fastdfs/client && \
	# install nginx with fastdfs-nginx-module
	tar -zxf fastdfs-nginx-module-1.20.tar.gz && \
	tar -zxf nginx-1.12.2.tar.gz && \
	rm nginx-1.12.2.tar.gz && \
	cd nginx-1.12.2 && \
	./configure --add-module=/usr/local/src/fastdfs-nginx-module-1.20/src && \
	make && \
	make install && \
	# copy config file
	mv -f /usr/local/src/mod_fastdfs.conf /etc/fdfs/ && \
	cp /usr/local/src/fastdfs-5.11/conf/http.conf /etc/fdfs/  && \
	cp /usr/local/src/fastdfs-5.11/conf/mime.types /etc/fdfs/ && \
	mkdir -p /fastdfs/storage/data/M00 && \
	ln -s /fastdfs/storage/data/ /fastdfs/storage/data/M00 && \
	mv /usr/local/src/nginx.conf /usr/local/nginx/conf/ && \
	cp /usr/lib64/libfdfsclient.so /usr/lib/ && \
	cd /usr/local/src && \
	# file used to start all service
	echo "/usr/bin/fdfs_trackerd /etc/fdfs/tracker.conf" > start.sh && \
	echo "/usr/bin/fdfs_storaged /etc/fdfs/storage.conf" >> start.sh && \
	echo "/usr/local/nginx/sbin/nginx" >> start.sh && \
	chmod +x /usr/local/src/start.sh
EXPOSE 80 8888 22122 23000