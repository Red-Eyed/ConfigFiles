#!/bin/bash

cd $(dirname $(readlink -f $0))

mkdir -p build/install
cd build

# on archlinux install:
# pacman -S gcc-fortran intel-tbb openblas cblas lapack lapacke eigen

cmake   -G "Ninja" \
        -DOpenGL_GL_PREFERENCE="GLVND" \
        -DCMAKE_INSTALL_PREFIX="/usr/local" \
        -DCMAKE_CXX_FLAGS="-march=native -O3" \
        -DCUDA_VERBOSE_BUILD=ON \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_CCACHE=ON \
        -DWITH_JPEG=ON \
        -DWITH_PNG=ON \
        -DWITH_TIFF=ON \
        -DWITH_EIGEN=ON \
        -DWITH_LAPACK=ON \
        -DWITH_CUDA=ON \
        -DWITH_CUDABLAS=ON \
        -DWITH_CUDNN=ON \
        -DWITH_OPENGL=ON \
        -DWITH_OPENCL=ON \
        -DWITH_QT=ON \
        -DWITH_TBB=ON \
        -DWITH_VULKAN=ON \
        -DWITH_IPP=ON \
        -DWITH_MKL=ON \
        -DMKL_WITH_TBB=ON \
        -DWITH_OPENCL_SVM=ON \
        -DOPENCV_EXTRA_MODULES_PATH="../../opencv_contrib/modules" \
        -DBUILD_NEW_PYTHON_SUPPORT=ON \
        -DBUILD_opencv_python3=ON \
        -DHAVE_opencv_python3=ON \
        -DPYTHON_DEFAULT_EXECUTABLE=$(which python3) \
        ../
