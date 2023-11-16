# -*- tab-width: 4 -*-

SRC_DIR					= source
DST_DIR					= ${HOME}/bin/_git
export PATH				:= ${DST_DIR}/bin:${PATH}
export LD_LIBRARY_PATH	:= ${DST_DIR}/lib:${LD_LIBRARY_PATH}

SRCS	= \
	https://archive.apache.org/dist/apr/apr-1.7.0.tar.gz \
	https://archive.apache.org/dist/apr/apr-util-1.6.1.tar.bz2 \
	https://curl.haxx.se/download/curl-7.73.0.tar.bz2 \
	https://github.com/git/git/archive/v2.29.2.tar.gz \
	https://notroj.github.io/neon/neon-0.31.2.tar.gz \
	https://www.openssl.org/source/openssl-1.1.1h.tar.gz \
	https://ftp.pcre.org/pub/pcre/pcre-8.44.tar.gz \
	https://www.cpan.org/src/5.0/perl-5.32.0.tar.gz \
	http://prdownloads.sourceforge.net/scons/scons-local-3.1.2.tar.gz \
	https://archive.apache.org/dist/serf/serf-1.3.9.tar.bz2 \
	https://www.sqlite.org/2021/sqlite-autoconf-3340100.tar.gz \
	https://archive.apache.org/dist/subversion/subversion-1.14.0.tar.gz \
	http://prdownloads.sourceforge.net/swig/swig-4.0.2.tar.gz

para:
	nice -n 19 $(MAKE) -j4 all 2>&1 | tee log

all: svn git

download:
	for url in $(SRCS); do \
		if [ ! -e $(SRC_DIR)/`basename $$url` ]; then wget -P $(SRC_DIR) --no-check-certificate $$url; fi; \
	done
	for url in $(SRCS); do \
		if [ ! -e $(SRC_DIR)/`basename $$url` ]; then echo "Failed:" `basename $$url`; fi; \
	done

perl:
	tar xf ${SRC_DIR}/perl-*.tar.*
	cd perl-*; \
	./Configure -des -Dprefix=${DST_DIR} -Dccflags=-L${DST_DIR}/lib -Dldflags=-L${DST_DIR}/lib; \
	$(MAKE); $(MAKE) install
	touch $@

pcre:
	tar xf ${SRC_DIR}/pcre-*.tar.*; \
	cd pcre-*; \
	./configure --prefix=${DST_DIR}; \
	$(MAKE); $(MAKE) install
	touch $@

swig: pcre perl
	tar xf ${SRC_DIR}/swig-*.tar.*
	cd swig-*; \
	./configure --prefix=${DST_DIR} --with-perl5=${DST_DIR}/bin/perl --with-pcre-prefix=${DST_DIR}; \
	$(MAKE); $(MAKE) install
	touch $@

apr:
	tar xf ${SRC_DIR}/apr-1*.tar.*
	cd apr-1*; \
	./configure --prefix=${DST_DIR}; \
	$(MAKE); $(MAKE) install
	touch $@

apr-util: apr
	tar xf ${SRC_DIR}/apr-util-*.tar.*
	cd apr-util-*; \
	./configure --prefix=${DST_DIR} --with-apr=${DST_DIR}/bin/apr-1-config; \
	$(MAKE); $(MAKE) install
	touch $@

sqlite:
	tar xf ${SRC_DIR}/sqlite-*.tar.*
	cd sqlite-*; mkdir build; cd build; \
	../configure --prefix=${DST_DIR} --disable-tcl; \
	$(MAKE); $(MAKE) install
	touch $@

serf: openssl apr apr-util
	source=`cd $(SRC_DIR); pwd`; mkdir scons-1; cd scons-1; tar xf $$source/scons-*.tar.*
	tar xf ${SRC_DIR}/serf-*.tar.*
	cd serf-*; \
	../scons-1/scons.py APR=${DST_DIR} APU=${DST_DIR} OPENSSL=${DST_DIR} PREFIX=${DST_DIR}; \
	../scons-1/scons.py install
	touch $@

svn: swig apr apr-util sqlite serf openssl
	tar xf ${SRC_DIR}/subversion-*.tar.*
	cd subversion-*; \
	./configure --prefix=${DST_DIR} --with-swig=${DST_DIR}/bin/swig PERL=${DST_DIR}/bin/perl --libdir=${DST_DIR}/lib \
		--with-apr=${DST_DIR} --with-apr-util=${DST_DIR} --with-sqlite=${DST_DIR} \
		--with-ssl=${DST_DIR} --with-serf=${DST_DIR} \
		--with-lz4=internal --with-utf8proc=internal; \
	$(MAKE); $(MAKE) swig-pl; \
	cp subversion/libsvn_delta/.libs/libsvn_delta-1.* ${DST_DIR}/lib; \
	$(MAKE) install; $(MAKE) install-swig-pl
	touch $@

curl: openssl
	tar xf ${SRC_DIR}/curl-*.tar.*
	cd curl-*; \
	./configure --prefix=${DST_DIR} --with-ssl=${DST_DIR}; \
	$(MAKE); $(MAKE) install
	touch $@

openssl:
	tar xf ${SRC_DIR}/openssl-*.tar.*
	cd openssl-*; \
	./config --prefix=${DST_DIR}; \
	$(MAKE); $(MAKE) install
	touch $@

git: curl openssl
	tar xf ${SRC_DIR}/v*.tar.*
	cd git-*; \
	$(MAKE) prefix=${DST_DIR} PERL_PATH=${DST_DIR}/bin/perl all; \
	$(MAKE) prefix=${DST_DIR} PERL_PATH=${DST_DIR}/bin/perl install
	touch $@

clean:
	rm -rf *-* `find . -maxdepth 1 -size 0` `ls -d ${DST_DIR}/*`
