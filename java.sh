#!/bin/bash

# Native JNI shared library compilation script
#
# This script compiles the native JNI sources into a shared library named
# either libwolfssljni.so/.dylib. Compiling on Linux/Unix and Mac OSX are
# currently supported.
#
# This script will attempt to auto-detect JAVA_HOME location if not set. To
# explicitly use a Java home location, set the JAVA_HOME environment variable
# prior to running this script.
#
# This script will try to link against a wolfSSL library installed to the
# default location of /usr/local. This script accepts one argument on the
# command line which can point to a custom wolfSSL installation location. A
# custom install location would match the directory set at wolfSSL
# ./configure --prefix=<DIR>.

OS=`uname`
ARCH=`uname -m`

if [ -z "$1" ]; then
    # default install location is /usr/local
    WOLFSSL_INSTALL_DIR="/usr/local"
else
    # use custom wolfSSL install location
    # should match directory set at wolfSSL ./configure --prefix=<DIR>
    WOLFSSL_INSTALL_DIR=$1
fi

echo "Compiling Native JNI library:"
echo "    WOLFSSL_INSTALL_DIR = $WOLFSSL_INSTALL_DIR"

if [ -z "$JAVA_HOME" ]; then
    # if JAVA_HOME not set, detect based on platform/OS
    echo "    JAVA_HOME empty, trying to detect"
else
    # user already set JAVA_HOME, use that
    echo "    JAVA_HOME already set = $JAVA_HOME"
    javaHome="$JAVA_HOME"
fi

# set up Java include and library paths for OS X and Linux
# NOTE: you may need to modify these if your platform uses different locations
if [ "$OS" == "Darwin" ] ; then
    echo "    Detected Darwin/OSX host OS"
    if [ -z $javaHome ]; then
        # this is broken since Big Sur, set JAVA_HOME environment var instead
        # OSX JAVA_HOME is typically similar to:
        #    /Library/Java/JavaVirtualMachines/jdk1.8.0_261.jdk/Contents/Home
        javaHome=`/usr/libexec/java_home`
    fi
    javaIncludes="-I$javaHome/include -I$javaHome/include/darwin -I$WOLFSSL_INSTALL_DIR/include"
    javaLibs="-dynamiclib"
    jniLibName="libwolfssljni.jnilib"
    cflags=""
elif [ "$OS" == "Linux" ] ; then
    echo "    Detected Linux host OS"
    if [ -z $javaHome ]; then
        javaHome=`echo $(dirname $(dirname $(readlink -f $(which java))))`
    fi
    if [ ! -d "$javaHome/include" ]
    then
        javaHome=`echo $(dirname $javaHome)`
    fi
    javaIncludes="-I$javaHome/include -I$javaHome/include/linux -I$WOLFSSL_INSTALL_DIR/include"
    javaLibs="-shared"
    jniLibName="libwolfssljni.so"
    cflags=""
    if [ "$ARCH" == "x86_64" ] ; then
        fpic="-fPIC"
    else
        fpic=""
    fi
else
    echo 'Unknown host OS!'
    exit
fi
echo "        $OS $ARCH"

echo "    Java Home = $javaHome"

# create /lib directory if doesn't exist
if [ ! -d ./lib ]
then
    mkdir ./lib
fi

gcc -Wall -c $fpic $cflags ./native/com_wolfssl_WolfSSL.c -o ./native/com_wolfssl_WolfSSL.o $javaIncludes
gcc -Wall -c $fpic $cflags ./native/com_wolfssl_WolfSSLSession.c -o ./native/com_wolfssl_WolfSSLSession.o $javaIncludes
gcc -Wall -c $fpic $cflags ./native/com_wolfssl_WolfSSLContext.c -o ./native/com_wolfssl_WolfSSLContext.o $javaIncludes
gcc -Wall -c $fpic $cflags ./native/com_wolfssl_wolfcrypt_RSA.c -o ./native/com_wolfssl_wolfcrypt_RSA.o $javaIncludes
gcc -Wall -c $fpic $cflags ./native/com_wolfssl_wolfcrypt_ECC.c -o ./native/com_wolfssl_wolfcrypt_ECC.o $javaIncludes
gcc -Wall -c $fpic $cflags ./native/com_wolfssl_wolfcrypt_EccKey.c -o ./native/com_wolfssl_wolfcrypt_EccKey.o $javaIncludes
gcc -Wall -c $fpic $cflags ./native/com_wolfssl_WolfSSLCertManager.c -o ./native/com_wolfssl_WolfSSLCertManager.o $javaIncludes
gcc -Wall -c $fpic $cflags ./native/com_wolfssl_WolfSSLCertificate.c -o ./native/com_wolfssl_WolfSSLCertificate.o $javaIncludes
gcc -Wall -c $fpic $cflags ./native/com_wolfssl_WolfSSLX509StoreCtx.c -o ./native/com_wolfssl_WolfSSLX509StoreCtx.o $javaIncludes
gcc -Wall $javaLibs $cflags -o ./lib/$jniLibName ./native/com_wolfssl_WolfSSL.o ./native/com_wolfssl_WolfSSLSession.o ./native/com_wolfssl_WolfSSLContext.o ./native/com_wolfssl_wolfcrypt_RSA.o ./native/com_wolfssl_wolfcrypt_ECC.o ./native/com_wolfssl_wolfcrypt_EccKey.o ./native/com_wolfssl_WolfSSLCertManager.o ./native/com_wolfssl_WolfSSLCertificate.o ./native/com_wolfssl_WolfSSLX509StoreCtx.o -L$WOLFSSL_INSTALL_DIR/lib -lwolfssl
if [ $? != 0 ]; then
    echo "Error creating native JNI library"
    exit 1
fi

echo "    Generated ./lib/$jniLibName"
