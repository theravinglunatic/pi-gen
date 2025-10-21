#!/bin/bash
# Pre-build verification script for FacelessWebServer Pi-Gen

set -e

# Change to script directory
cd "$(dirname "$0")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Pre-Build Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ERRORS=0
WARNINGS=0

# Function to check and report
check() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
        ERRORS=$((ERRORS + 1))
    fi
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

# Check config file
echo "📄 Checking configuration..."
if [ -f config ]; then
    check 0 "config file exists"
    
    grep -q "IMG_NAME='noface-pi5'" config && check 0 "IMG_NAME is set" || check 1 "IMG_NAME is not set correctly"
    grep -q "RELEASE='trixie'" config && check 0 "RELEASE='trixie'" || warn "RELEASE is not 'trixie'"
    grep -q 'STAGE_LIST="stage0 stage1 stage2 stage3"' config && check 0 "STAGE_LIST includes stage3" || check 1 "STAGE_LIST not configured"
    grep -q "FIRST_USER_NAME='noface'" config && check 0 "User is 'noface'" || check 1 "User not configured"
    grep -q "PUBKEY_SSH_FIRST_USER=" config && check 0 "SSH public key is set" || warn "SSH public key not set"
else
    check 1 "config file missing"
fi
echo ""

# Check stage3 files
echo "📦 Checking stage3 files..."
[ -f stage3/00-install-packages/00-packages ] && check 0 "00-packages exists" || check 1 "00-packages missing"
[ -f stage3/00-install-packages/00-packages-nr ] && check 0 "00-packages-nr exists" || check 1 "00-packages-nr missing"
[ -x stage3/01-clone-app/01-run.sh ] && check 0 "01-clone-app/01-run.sh is executable" || check 1 "01-clone-app/01-run.sh not executable"
[ -x stage3/01-clone-app/files/setup-faceless.sh ] && check 0 "setup-faceless.sh is executable" || check 1 "setup-faceless.sh not executable"
[ -x stage3/02-setup-service/01-run.sh ] && check 0 "02-setup-service/01-run.sh is executable" || check 1 "02-setup-service/01-run.sh not executable"
[ -f stage3/02-setup-service/files/Production-eth0.nmconnection ] && check 0 "Production-eth0.nmconnection exists" || check 1 "NetworkManager profile missing"
[ -f stage3/02-setup-service/files/Development-eth1.nmconnection ] && check 0 "Development-eth1.nmconnection exists" || check 1 "NetworkManager profile missing"
[ -f stage3/02-setup-service/files/no_face_core.service ] && check 0 "no_face_core.service exists" || check 1 "SystemD service missing"
[ -x stage3/03-first-boot/01-run.sh ] && check 0 "03-first-boot/01-run.sh is executable" || check 1 "03-first-boot/01-run.sh not executable"
[ -x stage3/03-first-boot/files/faceless-first-boot.sh ] && check 0 "faceless-first-boot.sh is executable" || check 1 "faceless-first-boot.sh not executable"
[ -f stage3/03-first-boot/files/faceless-first-boot.service ] && check 0 "faceless-first-boot.service exists" || check 1 "first-boot service missing"
echo ""

# Check SKIP files for unused directories
echo "🚫 Checking SKIP files..."
[ -f stage3/00-install-dependencies/SKIP ] && check 0 "00-install-dependencies skipped" || warn "00-install-dependencies not skipped"
[ -f stage3/01-print-support/SKIP ] && check 0 "01-print-support skipped" || warn "01-print-support not skipped"
echo ""

# Check system requirements
echo "🖥️  Checking system requirements..."
PAGE_SIZE=$(getconf PAGESIZE)
[ "$PAGE_SIZE" = "4096" ] && check 0 "Page size is 4K (armhf compatible)" || check 1 "Page size is $PAGE_SIZE (must be 4K for armhf)"

which debootstrap > /dev/null 2>&1 && check 0 "debootstrap installed" || check 1 "debootstrap not installed"
which qemu-arm-static > /dev/null 2>&1 && check 0 "qemu-arm-static installed" || check 1 "qemu-arm-static not installed"
which parted > /dev/null 2>&1 && check 0 "parted installed" || check 1 "parted not installed"
which zerofree > /dev/null 2>&1 && check 0 "zerofree installed" || check 1 "zerofree not installed"

DISK_SPACE=$(df -h . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "${DISK_SPACE%.*}" -ge 50 ]; then
    check 0 "Sufficient disk space (${DISK_SPACE}G available)"
else
    check 1 "Insufficient disk space (${DISK_SPACE}G available, need 50G+)"
fi
echo ""

# Check for spaces in path
echo "📂 Checking build path..."
if [[ "$PWD" =~ " " ]]; then
    check 1 "Path contains spaces (not supported)"
else
    check 0 "Path does not contain spaces"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed! Ready to build.${NC}"
    echo ""
    echo "Run: sudo ./build.sh"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS warnings found. Review and proceed with caution.${NC}"
    echo ""
    echo "You can proceed with: sudo ./build.sh"
else
    echo -e "${RED}❌ $ERRORS errors and $WARNINGS warnings found. Fix errors before building.${NC}"
    exit 1
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
