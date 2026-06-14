# ==========================================
# Stage 1: Build Chiaki v2.2.0 from source
# ==========================================
FROM ubuntu:22.04 AS builder

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install compilation and package dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    cmake \
    build-essential \
    qtbase5-dev \
    qtmultimedia5-dev \
    libqt5svg5-dev \
    libqt5opengl5-dev \
    libopus-dev \
    libssl-dev \
    libsdl2-dev \
    libprotobuf-dev \
    protobuf-compiler \
    python3-protobuf \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libswresample-dev \
    libswscale-dev \
    libasound2-dev \
    libpulse-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Clone the repository recursively at tag v2.2.0
WORKDIR /src
RUN git clone --recursive --branch v2.2.0 https://git.sr.ht/~thestr4ng3r/chiaki .

# Compile Chiaki
WORKDIR /src/build
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr .. && \
    make -j$(nproc) && \
    make install DESTDIR=/install

# ==========================================
# Stage 2: Clean runtime environment
# ==========================================
FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies (including GUI, audio, FFmpeg, SDL2, and GPU drivers)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libqt5multimedia5 \
    libqt5multimedia5-plugins \
    libqt5svg5 \
    libqt5widgets5 \
    libqt5gui5 \
    libqt5core5a \
    libqt5opengl5 \
    libopus0 \
    libssl3 \
    libsdl2-2.0-0 \
    libprotobuf23 \
    pulseaudio \
    alsa-utils \
    libgl1-mesa-dri \
    libgl1-mesa-glx \
    mesa-vulkan-drivers \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled binary and assets from builder
COPY --from=builder /install/usr /usr

# Create user chiaki with default UID/GID
RUN useradd -m -s /bin/bash chiaki

USER chiaki
WORKDIR /home/chiaki

# Environment variables for X11 forwarding
ENV DISPLAY=:0
ENV QT_X11_NO_MITSHM=1

ENTRYPOINT ["/usr/bin/chiaki"]
