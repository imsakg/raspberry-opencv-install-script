#!/bin/bash

set -ex

# Dependencies

sudo apt-get purge wolfram-engine
sudo apt-get purge -y libreoffice*
sudo apt-get clean
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get autoremove -y

sudo dphys-swapfile swapoff
sudo sed -i 's:CONF_SWAPSIZE=.*:CONF_SWAPSIZE=2048:g' /etc/dphys-swapfile
sudo reboot

sudo apt-get install tmux neovim

sudo apt-get install cmake gcc g++ python3-dev python3-numpy libavcodec-dev libavformat-dev libswscale-dev libgstreamer-plugins-base1.0-dev libgstreamer1.0-dev libgtk-3-dev libpng-dev libjpeg-dev libopenexr-dev libtiff-dev libwebp-dev file git wget unzip yasm libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libpq-dev libsdl-image1.2-dev libsdl-mixer1.2-dev libsdl-ttf2.0-dev libsdl1.2-dev libsmpeg-dev subversion libportmidi-dev ffmpeg libswscale-dev libavformat-dev libavcodec-dev libfreetype6-dev libzbar-dev libopencv-dev wiringpi devscripts debhelper cmake libldap2-dev libgtkmm-3.0-dev libarchive-dev libcurl4-openssl-dev intltool build-essential cmake pkg-config libjpeg-dev libtiff5-dev libjasper-dev libavcodec-dev libavformat-dev libswscale-dev libv4l-dev libxvidcore-dev libx264-dev libgtk2.0-dev libgtk-3-dev libatlas-base-dev libblas-dev libeigen{2,3}-dev liblapack-dev gfortran python2.7-dev python3-dev python-pip python3-pip python python3 meson flex bison libglib2.0-dev libglib2.0-dev

# GStreamer Base
wget https://gstreamer.freedesktop.org/src/gstreamer/gstreamer-1.18.4.tar.xz
sudo tar -xf gstreamer-1.18.4.tar.xz
cd gstreamer-1.18.4
mkdir build
cd build
meson --prefix=/usr       \
        --wrap-mode=nofallback \
        -D buildtype=release \
        -D gst_debug=false   \
        -D package-origin=https://gstreamer.freedesktop.org/src/gstreamer/ \
        -D package-name="GStreamer 1.18.4 BLFS" ..

ninja -j4
ninja test # Optional
sudo ninja install
sudo ldconfig

# GStreamer Plugins-Good
cd ~
wget https://gstreamer.freedesktop.org/src/gst-plugins-base/gst-plugins-base-1.18.4.tar.xz
sudo tar -xf gst-plugins-base-1.18.4.tar.xz
cd gst-plugins-base-1.18.4
mkdir build
cd build
meson --prefix=/usr \
-D buildtype=release \
-D package-origin=https://gstreamer.freedesktop.org/src/gstreamer/ ..
ninja -j4
ninja test # optional
sudo ninja install
sudo ldconfig

# GStreamer Plugins-Good
cd ~
wget https://gstreamer.freedesktop.org/src/gst-plugins-good/gst-plugins-good-1.18.4.tar.xz
sudo tar -xf gst-plugins-good-1.18.4.tar.xz
cd gst-plugins-good-1.18.4
mkdir build
cd build
meson --prefix=/usr       \
       -D buildtype=release \
       -D package-origin=https://gstreamer.freedesktop.org/src/gstreamer/ \
       -D package-name="GStreamer 1.18.4 BLFS" ..
ninja -j4
ninja test # optional
sudo ninja install
sudo ldconfig


# Upgrade pip & install numpy

sudo pip2 install -U pip
sudo pip3 install -U pip
sudo pip2 install numpy
sudo pip3 install numpy

# Set Veriables

OPENCV_VERSION=4.5.3
cd ~
mkdir -p opencv && pushd opencv

# Download

wget -O "opencv-${OPENCV_VERSION}.tar.gz" "https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.tar.gz"
wget -O "opencv_contrib-${OPENCV_VERSION}.tar.gz" "https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.tar.gz"
tar -xvf "opencv-${OPENCV_VERSION}.tar.gz"
tar -xvf "opencv_contrib-${OPENCV_VERSION}.tar.gz"
popd

# Build

pushd ~/opencv/opencv-$OPENCV_VERSION
mkdir -p build
pushd build
RPI_VERSION=$(awk '{print $3}' < /proc/device-tree/model)
if [[ $RPI_VERSION -ge 4 ]]; then
  NUM_JOBS=$(nproc)
else
  NUM_JOBS=1 # Earlier versions of the Pi don't have sufficient RAM to support compiling with multiple jobs.
fi

# -D ENABLE_PRECOMPILED_HEADERS=OFF
# is a fix for https://github.com/opencv/opencv/issues/14868

# -D OPENCV_EXTRA_EXE_LINKER_FLAGS=-latomic
# is a fix for https://github.com/opencv/opencv/issues/15192

cmake -D CMAKE_BUILD_TYPE=RELEASE \
      -D CMAKE_INSTALL_PREFIX=/usr/local \
      -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-$OPENCV_VERSION/modules \
      -D OPENCV_ENABLE_NONFREE=ON \
      -D BUILD_PERF_TESTS=OFF \
      -D BUILD_TESTS=OFF \
      -D BUILD_DOCS=OFF \
      -D BUILD_EXAMPLES=OFF \
      -D ENABLE_PRECOMPILED_HEADERS=OFF \
      -D WITH_OPENMP=OFF \
      -D ENABLE_NEON=OFF \
      -D ENABLE_VFPV3=OFF \
      -D BUILD_TBB=OFF \
      -D OPENCV_EXTRA_EXE_LINKER_FLAGS=-latomic \
      -D PYTHON3_EXECUTABLE=$(which python3) \
      -D PYTHON_EXECUTABLE=$(which python2) \
      ..
make -j "$NUM_JOBS"
sudo make install
popd; popd
