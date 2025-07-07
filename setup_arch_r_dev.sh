#!/bin/bash

# ==============================================================================
# Arch Linux Setup Script for R and Rust Development
#
# This script installs all necessary system and R packages to work on the
# RCBOR project. It is intended for a fresh Arch Linux environment.
#
# It will:
# 1. Update the system package database and upgrade installed packages.
# 2. Generate a standard locale to prevent warnings.
# 3. Install R, the Rust toolchain, and essential build tools using pacman.
# 4. Install the required R packages for development from CRAN.
#
# How to run:
# 1. Save this file as `setup_arch_r_dev.sh`
# 2. Make it executable: `chmod +x setup_arch_r_dev.sh`
# 3. Run it: `./setup_arch_r_dev.sh`
# ==============================================================================

set -e # Exit immediately if a command exits with a non-zero status.

# --- Step 1: Install System Dependencies with pacman ---
echo "--> Updating system and installing system dependencies with pacman..."
echo "--> This will require sudo privileges."

sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm \
    r \
    rustup \
    base-devel \
    openssl \
    libxml2

# Set the default Rust toolchain to stable
rustup default stable
echo "--> System dependencies installed."
echo ""

# --- Step 2: Generate Locale to prevent R warnings ---
echo "--> Generating en_US.UTF-8 locale..."
# Uncomment the en_US.UTF-8 locale in the config file
sudo sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
# Generate the locale
sudo locale-gen
echo "--> Locale generated."
echo ""


# --- Step 3: Install R Packages from CRAN ---
echo "--> Installing required R packages for development..."

# List of packages needed for the RCBOR project and general development
R_PACKAGES=(
    "devtools"
    "usethis"
    "roxygen2"
    "rextendr"
    "testthat"
    "rmarkdown"
    "knitr"
    "badger"
    "bench"
    "jsonlite"
)

# Create a single R command string to install all packages
PKG_STRING=""
for pkg in "${R_PACKAGES[@]}"; do
    PKG_STRING+="\"$pkg\","
done
# Remove the trailing comma
PKG_STRING=${PKG_STRING%,}

# Execute the R command
# FIX: Run the R command with sudo to allow installation to system library
# This uses the R cloud mirror, which automatically selects a fast mirror.
sudo R -e "install.packages(c($PKG_STRING), repos='https://cloud.r-project.org/')"

echo ""
echo "--> All R packages have been installed."
echo "--> Your Arch Linux system is now ready for R development with Rust!"
echo "--> You can now open the RCBOR project in Emacs and use ESS."

