#!/bin/env bash

if [ $# -ne 1 ]; then
	echo "Usage: $0 <PREFIX>"
	exit 1
fi

pwd_path=`pwd`

TMP=$HOME/download
FUNC_PREFIX=$1
PYTHON_PREFIX=$FUNC_PREFIX
OPENSSL_PREFIX=$HOME/local/openssl

export LD_LIBRARY_PATH=$OPENSSL_PREFIX/lib
export C_INCLUDE_PATH=$OPENSSL_PREFIX/include

if [ -d $OPENSSL_PREFIX ]; then
    echo "[WARN] Will not install openssl again, since directory $OPENSSL_PREFIX has existed"
	read -p "Press any key to continue ..."
fi

if [ -d $PYTHON_PREFIX ]; then
    echo "[WARN] Will not install python again, since directory $PYTHON_PREFIX has existed"
	read -p "Press any key to continue ..."
fi

mkdir -p $TMP

if [ ! -d $OPENSSL_PREFIX ]; then
    DEPEND=openssl-1.0.1e
    if [ ! -f $TMP/${DEPEND}.tar.gz ]; then
		#wget -P $TMP http://www.openssl.org/source/${DEPEND}.tar.gz
        wget -P $TMP http://myhost/${DEPEND}.tar.gz
    fi
    if [ -d $TMP/${DEPEND} ]; then
        rm -rf $TMP/${DEPEND}
    fi

    cd $TMP \
    && tar xf ${DEPEND}.tar.gz \
    && cd $DEPEND \
    && ./config --prefix=$OPENSSL_PREFIX shared \
    && make clean && make && make install \
    && rm -rf $TMP/${DEPEND}

    if [ $? -ne 0 ]; then
        exit 1
    fi
fi

if [ ! -d $PYTHON_PREFIX ]; then
    DEPEND=Python-2.7.3
    if [ ! -f $TMP/${DEPEND}.tar.bz2 ]; then
		#wget -P $TMP http://www.python.org/ftp/python/2.7.3/${DEPEND}.tar.bz2
        wget -P $TMP http://myhost/${DEPEND}.tar.bz2
    fi
    if [ -d $TMP/${DEPEND} ]; then
        rm -rf $TMP/${DEPEND}
    fi

    cd $TMP \
    && tar xf ${DEPEND}.tar.bz2 \
    && cd $DEPEND \
    && sed -i \
            -e "s/^#_md5 /_md5 /" \
            -e "s/^#_sha/_sha/" \
            Modules/Setup.dist \
    && ./configure --prefix=$PYTHON_PREFIX CPPFLAGS='-I$(HOME)/local/openssl/include' LDFLAGS='-L$(HOME)/local/openssl/lib' \
    && make clean && make && make install \
    && rm -rf $TMP/${DEPEND}

    if [ $? -ne 0 ]; then
        exit 1
    fi
fi

cp -f $OPENSSL_PREFIX/lib/lib*.so.1.* $PYTHON_PREFIX/lib/ && \
cd $pwd_path && \
cp -f $OPENSSL_PREFIX/lib/lib*.so.1.* ../lib/

for DEPEND in certmaster-0.28-uc func-0.28-uc pyOpenSSL-0.13 simplejson-3.3.0
do

    if [ ! -f $TMP/${DEPEND}.tar.gz ]; then
		wget -P $TMP http://myhost/${DEPEND}.tar.gz 
	fi
    if [ -d $TMP/${DEPEND} ]; then
        rm -rf $TMP/${DEPEND}
    fi

    cd $TMP \
    && tar xf ${DEPEND}.tar.gz \
    && cd $DEPEND \
    && LDFLAGS="-L../lib -Wl,-rpath ../lib" $PYTHON_PREFIX/bin/python setup.py install \
    && rm -rf $TMP/${DEPEND}

    if [ $? -ne 0 ]; then
        exit 1
    fi
done

echo -e "\n\n------------------Summary----------------------
[INSTALLED INFO]:
Location of downloaded files: $TMP
Installed path of OpenSSL: $OPENSSL_PREFIX
Installed path of Python: $PYTHON_PREFIX
Installed path of Func: $FUNC_PREFIX
-----------------------------------------------"
