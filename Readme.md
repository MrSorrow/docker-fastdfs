## I. 环境版本

- Docker CE
- [fastdfs-5.11.tar.gz](https://github.com/happyfish100/fastdfs/releases)
- [fastdfs-nginx-module-1.20.tar.gz](https://github.com/happyfish100/fastdfs-nginx-module/releases)
- [libfastcommon-1.0.38.tar.gz](https://github.com/happyfish100/libfastcommon/releases)
- [nginx-1.12.2.tar.gz](http://nginx.org/download/nginx-1.12.2.tar.gz)
- 镜像：[coffeecoder/fastdfs](https://hub.docker.com/r/coffeecoder/fastdfs/) 

## II. 安装步骤

1. 拉取镜像；

   ```bash
   docker pull coffeecoder/fastdfs:1.0
   ```

2. 启动容器；

   ```bash
   docker run -itd --name taotao-fastdfs -p 80:80 -p 8888:8888 -p 22122:22122 -p 23000:23000 coffeecoder/fastdfs:1.0 /bin/bash
   ```

3. 启动tracker、storage、nginx服务；

   ```bash
   docker exec -it taotao-fastdfs /bin/bash
   ./start.sh
   ```

4. 测试图片上传；

   ```bash
   cd fastdfs-5.11/conf
   /usr/bin/fdfs_test /etc/fdfs/client.conf upload anti-steal.jpg
   ```

## III. Dockerfile构建FastDFS镜像

1. 下载所有需要文件，本人已经上传至github仓库；

2. 修改 `storage.conf`、`mod_fastdfs.conf`、`client.conf` 中ip地址为自己的ip；

3. 利用工具修改 fastdfs-nginx-module-1.20.tar.gz 中 `src/config` 文件内容（我的已经修改好）；

   ```bash
   ngx_addon_name=ngx_http_fastdfs_module
   
   if test -n "${ngx_module_link}"; then
       ngx_module_type=HTTP
       ngx_module_name=$ngx_addon_name
       ngx_module_incs="/usr/include/fastdfs /usr/include/fastcommon/"
       ngx_module_libs="-lfastcommon -lfdfsclient"
       ngx_module_srcs="$ngx_addon_dir/ngx_http_fastdfs_module.c"
       ngx_module_deps=
       CFLAGS="$CFLAGS -D_FILE_OFFSET_BITS=64 -DFDFS_OUTPUT_CHUNK_SIZE='256*1024' -DFDFS_MOD_CONF_FILENAME='\"/etc/fdfs/mod_fastdfs.conf\"'"
       . auto/module
   else
       HTTP_MODULES="$HTTP_MODULES ngx_http_fastdfs_module"
       NGX_ADDON_SRCS="$NGX_ADDON_SRCS $ngx_addon_dir/ngx_http_fastdfs_module.c"
       CORE_INCS="$CORE_INCS /usr/include/fastdfs /usr/include/fastcommon/"
       CORE_LIBS="$CORE_LIBS -lfastcommon -lfdfsclient"
       CFLAGS="$CFLAGS -D_FILE_OFFSET_BITS=64 -DFDFS_OUTPUT_CHUNK_SIZE='256*1024' -DFDFS_MOD_CONF_FILENAME='\"/etc/fdfs/mod_fastdfs.conf\"'"
   fi
   ```

4. 编写Dockerfile；

   ```bash
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
   ```

5. 构建镜像；

   ```bash
   docker build -t="coffeecoder/fastdfs:1.0" .
   ```

