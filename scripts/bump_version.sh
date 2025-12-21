#!/bin/bash
# bump_version.sh - Update version and create release tag
# Usage: ./scripts/bump_version.sh <version>
# Example: ./scripts/bump_version.sh 1.0.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check arguments
if [ -z "$1" ]; then
    echo -e "${RED}Error: Version argument required${NC}"
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.0"
    exit 1
fi

VERSION=$1
TAG="v${VERSION}"

# Validate version format (semver)
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
    echo -e "${RED}Error: Invalid version format${NC}"
    echo "Version must be semver format: X.Y.Z or X.Y.Z-suffix"
    echo "Examples: 1.0.0, 1.0.0-beta.1, 2.1.0-rc.1"
    exit 1
fi

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if we're in a git repository
if ! git -C "$PROJECT_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Check for uncommitted changes
if ! git -C "$PROJECT_ROOT" diff --quiet HEAD 2>/dev/null; then
    echo -e "${YELLOW}Warning: You have uncommitted changes${NC}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if tag already exists
if git -C "$PROJECT_ROOT" tag -l "$TAG" | grep -q "$TAG"; then
    echo -e "${RED}Error: Tag $TAG already exists${NC}"
    exit 1
fi

echo -e "${GREEN}Updating version to ${VERSION}...${NC}"

# Update pubspec.yaml
PUBSPEC="$PROJECT_ROOT/pubspec.yaml"
if [ -f "$PUBSPEC" ]; then
    # Extract current build number and increment it
    CURRENT_BUILD=$(grep -E "^version:" "$PUBSPEC" | sed -E 's/.*\+([0-9]+)$/\1/')
    if [ -z "$CURRENT_BUILD" ]; then
        CURRENT_BUILD=0
    fi
    NEW_BUILD=$((CURRENT_BUILD + 1))

    # Update version line
    sed -i.bak -E "s/^version: .*/version: ${VERSION}+${NEW_BUILD}/" "$PUBSPEC"
    rm -f "$PUBSPEC.bak"
    echo -e "  ${GREEN}Updated pubspec.yaml: ${VERSION}+${NEW_BUILD}${NC}"
else
    echo -e "${RED}Error: pubspec.yaml not found${NC}"
    exit 1
fi

# Commit the version change
echo -e "${GREEN}Committing version change...${NC}"
git -C "$PROJECT_ROOT" add "$PUBSPEC"
git -C "$PROJECT_ROOT" commit -m "chore: bump version to ${VERSION}"

# Create tag
echo -e "${GREEN}Creating tag ${TAG}...${NC}"
git -C "$PROJECT_ROOT" tag -a "$TAG" -m "Release ${VERSION}"

# Ask to push
echo ""
echo -e "${YELLOW}Version updated and tag created locally.${NC}"
echo -e "To trigger the release build, push the tag:"
echo -e "  ${GREEN}git push origin main && git push origin ${TAG}${NC}"
echo ""
read -p "Push now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git -C "$PROJECT_ROOT" push origin main
    git -C "$PROJECT_ROOT" push origin "$TAG"
    echo -e "${GREEN}Pushed! GitHub Actions will build the release.${NC}"
    echo -e "Check progress at: https://github.com/r9r-dev/conduit/actions"
fi
