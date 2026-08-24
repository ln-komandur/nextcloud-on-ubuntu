#!/bin/bash

#ref: https://unix.stackexchange.com/questions/28791/prompt-for-sudo-password-and-programmatically-elevate-privilege-in-bash-script
#ref: https://askubuntu.com/a/30157/8698
#ref: https://mariadb.com/docs/server/server-management/install-and-upgrade-mariadb/mariadb-package-repository-setup-and-usage
#
if (($EUID != 0)); then # Only elevate if not already running as root
  if [[ -t 1 ]]; then
    #https://unix.stackexchange.com/questions/218715/what-does-t-1-do
    sudo "$0" "$@" # Re-run this script as root, preserving arguments
  else
    exec 1>output_file # No interactive terminal, redirect output for gksu
    gksu "$0 $@" # Fall back to gksu for privilege elevation
  fi
  exit
fi

echo "This script installs MariaDB for Nextcloud server installation"
echo "##############################################################"
echo
echo
echo

# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------

REPO_SETUP_URL="https://r.mariadb.com/downloads/mariadb_repo_setup" # Official MariaDB Community repo setup utility
REPO_SETUP_SCRIPT="mariadb_repo_setup" # Local filename for the downloaded utility
CHECKSUM_DOCS_URL="https://mariadb.com/docs/server/server-management/install-and-upgrade-mariadb/mariadb-package-repository-setup-and-usage.md" # Markdown docs page containing the checksum table
OLD_MIRROR_STRING="mirror.mariadb.org" # Marker string used to find/remove the old dead mirror repo entry
OLD_REPO_LINE="deb [arch=amd64] http://mirror.mariadb.org/repo/10.11/ubuntu/ jammy main" # Exact line the old script added, for a clean --remove

# Supported MariaDB Community Server versions (kept in sync manually with the docs page)
# See: https://mariadb.com/docs/server/server-management/install-and-upgrade-mariadb/mariadb-package-repository-setup-and-usage#the-mariadb-server-version-option
MARIADB_VERSIONS=(
  "mariadb-10.6"
  "mariadb-10.11"
  "mariadb-11.4"
  "mariadb-11.8"
  "mariadb-11.rolling"
  "mariadb-11.rc"
  "mariadb-12.1"
  "mariadb-12.2"
  "mariadb-12.rolling"
  "mariadb-12.rc"
)
DEFAULT_VERSION_INDEX=9 # Index (1-based, matches menu) of "mariadb-12.rolling" as the default

# ----------------------------------------------------------------------------
# Step 1: Let the user choose which MariaDB Community Server version to install
# ----------------------------------------------------------------------------

echo "Select the MariaDB Community Server version to install"
echo "########################################################################"
echo
for i in "${!MARIADB_VERSIONS[@]}"; do # Print the numbered menu
  num=$((i + 1))
  if ((num == DEFAULT_VERSION_INDEX)); then
    echo "  $num) ${MARIADB_VERSIONS[$i]} (default)"
  else
    echo "  $num) ${MARIADB_VERSIONS[$i]}"
  fi
done
echo

MARIADB_VERSION="" # Will hold the final chosen version string
while [[ -z "$MARIADB_VERSION" ]]; do # Keep prompting until a valid selection is made
  read -rp "Enter number [$DEFAULT_VERSION_INDEX]: " selection # Prompt the user, showing the default
  if [[ -z "$selection" ]]; then # Empty input means accept the default
    MARIADB_VERSION="${MARIADB_VERSIONS[$((DEFAULT_VERSION_INDEX - 1))]}"
  elif [[ "$selection" =~ ^[0-9]+$ ]] && ((selection >= 1 && selection <= ${#MARIADB_VERSIONS[@]})); then # Valid numeric choice
    MARIADB_VERSION="${MARIADB_VERSIONS[$((selection - 1))]}"
  else
    echo "Invalid selection. Please enter a number between 1 and ${#MARIADB_VERSIONS[@]}, or press Enter for the default." # Re-prompt on bad input
  fi
done

echo
echo "Selected version: $MARIADB_VERSION"
echo
echo
echo

# ----------------------------------------------------------------------------
# Step 2: Install prerequisites for mariadb_repo_setup (and for add-apt-repository, used next)
# ----------------------------------------------------------------------------

echo "Install prerequisites for the MariaDB repo setup utility"
echo "########################################################################"
echo
apt update # Refresh package lists before installing prerequisites
nala install curl apt-transport-https software-properties-common # Required by mariadb_repo_setup, plus software-properties-common (provides add-apt-repository) used in the next step
echo
echo
echo

# ----------------------------------------------------------------------------
# Step 3: Remove the old, dead mirror.mariadb.org repo entry and its key
# ----------------------------------------------------------------------------

echo "Remove old mirror.mariadb.org repository entry (dead as of this repo's last release)"
echo "########################################################################"
echo

STALE_FILES=() # Files that actually contain a reference to the old dead mirror
for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
  [[ -f "$f" ]] || continue
  if grep -q "$OLD_MIRROR_STRING" "$f" 2>/dev/null; then
    STALE_FILES+=("$f")
  fi
done

if ((${#STALE_FILES[@]} == 0)); then
  echo "No existing $OLD_MIRROR_STRING repository entry found on this system — nothing to remove."
else
  echo "Found existing $OLD_MIRROR_STRING entry in: ${STALE_FILES[*]}"
  echo
  if command -v add-apt-repository >/dev/null 2>&1; then # Only attempt if add-apt-repository exists
    echo "NOTE: add-apt-repository will show the repository details below and then pause,"
    echo "waiting for you to press ENTER to confirm removal (or Ctrl-C to cancel)."
    echo
    add-apt-repository --remove "$OLD_REPO_LINE" # Undo the exact line the old script added. Do NOT redirect/suppress stderr — the confirmation prompt is written there, and do NOT pass -y — the user should explicitly confirm.
  fi
  echo
  echo "Scanning apt sources for any remaining references to $OLD_MIRROR_STRING"
  echo
  for f in "${STALE_FILES[@]}"; do # Belt-and-suspenders sweep in case add-apt-repository didn't catch it (e.g. entry was added/edited another way)
    if grep -q "$OLD_MIRROR_STRING" "$f" 2>/dev/null; then # Re-check: add-apt-repository above may have already removed it
      echo "Found stale entry in $f — removing matching line(s)"
      sed -i "/$OLD_MIRROR_STRING/d" "$f" # Strip only the offending line(s), leave the rest of the file intact
    fi
  done
fi
echo

echo "Remove old deprecated apt-key signing key for MariaDB, if present"
echo "########################################################################"
echo
if command -v apt-key >/dev/null 2>&1; then # apt-key itself is deprecated but may still exist on the system
  OLD_KEY_ID=$(apt-key list 2>/dev/null | grep -B 1 -i "mariadb" | grep -Eo '[0-9A-F]{4}( [0-9A-F]{4}){9}' | tr -d ' ' | head -n1) # Locate the MariaDB key fingerprint, if any
  if [[ -n "$OLD_KEY_ID" ]]; then
    echo "Removing old MariaDB signing key: $OLD_KEY_ID"
    apt-key del "$OLD_KEY_ID" 2>/dev/null # Remove the legacy key so it can't conflict with the new one
  else
    echo "No old MariaDB key found in apt-key's legacy keyring."
  fi
else
  echo "apt-key not present on this system — nothing to remove."
fi
echo
echo
echo

# ----------------------------------------------------------------------------
# Step 4: Download mariadb_repo_setup and verify its checksum
# ----------------------------------------------------------------------------

echo "Download the official MariaDB Community repo setup utility"
echo "########################################################################"
echo
curl -LsSO "$REPO_SETUP_URL" # Download the utility fresh each run so it always reflects the latest version
chmod +x "$REPO_SETUP_SCRIPT" # Make it executable
echo

SCRIPT_VERSION=$(./"$REPO_SETUP_SCRIPT" --version 2>/dev/null | grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -n1) # Extract the dated version string, e.g. 2026-06-30
echo "Downloaded script version: ${SCRIPT_VERSION:-unknown}"
echo

echo "Attempt automated checksum verification"
echo "########################################################################"
echo
EXPECTED_CHECKSUM=""
if [[ -n "$SCRIPT_VERSION" ]]; then
  # Fetch the markdown docs page containing the checksum tables, then normalize it:
  # markdown sources commonly escape underscores inside identifiers (e.g. mariadb\_repo\_setup)
  # to prevent them being read as italics. Un-escape those before any text matching below,
  # so header/table matching works regardless of whether escaping is present.
  DOCS_MD=$(curl -LsS "$CHECKSUM_DOCS_URL" 2>/dev/null | sed 's/\\_/_/g')
  if [[ -n "$DOCS_MD" ]]; then
    # IMPORTANT: the docs page contains TWO checksum tables in its "Versions" section —
    # one for mariadb_es_repo_setup (Enterprise) and one for mariadb_repo_setup (Community) —
    # and they can share the same dated version with DIFFERENT checksums. The Enterprise
    # table appears first on the page, so a naive whole-page grep silently matches the
    # wrong (Enterprise) checksum. Scope the search to only the Community table: start
    # capturing at the "mariadb_repo_setup Versions" heading (which, unlike
    # "mariadb_es_repo_setup Versions", does not match "es_repo_setup"), and stop at the
    # next {% endtab %} marker.
    CS_TABLE=$(echo "$DOCS_MD" | awk '
      /mariadb_repo_setup Versions/ && !/es_repo_setup/ { grab=1; next }
      grab && /{% *endtab *%}/ { exit }
      grab { print }
    ')
    # Table rows look like: | 2026-06-30    | `7325ac7755809ca...` |
    EXPECTED_CHECKSUM=$(echo "$CS_TABLE" | grep -E "^\| *${SCRIPT_VERSION} *\|" | grep -Eo '`[0-9a-f]{40,}`' | tr -d '`' | head -n1)
    if [[ -z "$EXPECTED_CHECKSUM" ]]; then
      # Fallback: if the scoped table search still found nothing (e.g. heading text on
      # this page differs from what we expect), fall back to a whole-page search rather
      # than reporting a false negative. This can still match the wrong (Enterprise) table
      # in the rare case both scripts share an exact release date, so it is a fallback,
      # not the primary path.
      EXPECTED_CHECKSUM=$(echo "$DOCS_MD" | grep -E "^\| *${SCRIPT_VERSION} *\|" | grep -Eo '`[0-9a-f]{40,}`' | tr -d '`' | head -n1)
    fi
  fi
fi

if [[ -n "$EXPECTED_CHECKSUM" ]]; then # Found a checksum to check against
  ACTUAL_CHECKSUM=$(sha256sum "$REPO_SETUP_SCRIPT" | awk '{print $1}')
  if [[ "$ACTUAL_CHECKSUM" == "$EXPECTED_CHECKSUM" ]]; then
    echo "Checksum verified successfully for version $SCRIPT_VERSION."
  else
    echo "CHECKSUM MISMATCH for version $SCRIPT_VERSION."
    echo "Expected: $EXPECTED_CHECKSUM"
    echo "Actual:   $ACTUAL_CHECKSUM"
    echo "This could mean a corrupted download or a tampered file."
    read -rp "Type 'PROCEED' to continue anyway, or anything else to abort: " mismatch_choice
    if [[ "$mismatch_choice" != "PROCEED" ]]; then
      echo "Aborting due to checksum mismatch."
      exit 1
    fi
    echo "Proceeding despite checksum mismatch, at user's request."
  fi
else
  # Could not find a checksum for this version — likely the docs table layout changed, or a network issue
  echo "Could not locate a checksum for version ${SCRIPT_VERSION:-unknown} in the MariaDB docs table."
  echo "This may mean MariaDB changed the layout of their docs page, the docs site is unreachable,"
  echo "or this script's parsing needs updating — it does not necessarily mean the download is bad."
  echo
  echo "Options:"
  echo "  1) I have verified the checksum manually (see $CHECKSUM_DOCS_URL) — proceed"
  echo "  2) Proceed anyway, unverified (accept the risk)"
  echo "  3) Abort"
  read -rp "Enter choice [3]: " checksum_choice
  case "$checksum_choice" in
    1|2)
      echo "Proceeding without automated checksum verification."
      ;;
    *)
      echo "Aborting. You can verify manually with:"
      echo "  echo \"<checksum> $REPO_SETUP_SCRIPT\" | sha256sum -c -"
      echo "using the checksum for version ${SCRIPT_VERSION:-unknown} from:"
      echo "  $CHECKSUM_DOCS_URL"
      exit 1
      ;;
  esac
fi
echo
echo
echo

# ----------------------------------------------------------------------------
# Step 5: Run mariadb_repo_setup for the chosen version
# ----------------------------------------------------------------------------

echo "Configure the MariaDB repository for $MARIADB_VERSION on this system"
echo "########################################################################"
echo
./"$REPO_SETUP_SCRIPT" --mariadb-server-version="$MARIADB_VERSION" # Writes repo config, imports the correct key, and runs apt update
echo

REPO_CONFIG_FOUND=0
for f in /etc/apt/sources.list.d/mariadb.sources /etc/apt/sources.list.d/mariadb.list; do
  if [[ -f "$f" ]]; then
    echo "Repository configuration file created: $f"
    REPO_CONFIG_FOUND=1
  fi
done
if ((REPO_CONFIG_FOUND == 0)); then
  echo "WARNING: No mariadb.sources or mariadb.list file was found under /etc/apt/sources.list.d/."
  echo "mariadb_repo_setup may have failed partway through. The MariaDB repository is likely NOT configured."
  echo "Review the output above before proceeding — installation below will probably fail."
fi
echo
echo
echo

# ----------------------------------------------------------------------------
# Step 6: Update repos and install MariaDB server and client
# ----------------------------------------------------------------------------

echo "Update repos"
echo "##############################################################"
echo
apt update # Update repos now that the new MariaDB repo is configured
echo
echo

echo "Repository update complete."
echo
echo "Proceed with installing mariadb-server and mariadb-client, or stop here now that the"
echo "repository is configured?"
echo
read -rp "Type 'INSTALL' to proceed with installation, or anything else to stop here: " install_choice
if [[ "$install_choice" != "INSTALL" ]]; then
  echo
  echo "Stopping here as requested. The MariaDB repository is configured; no packages were installed."
  echo "Re-run this script and confirm at this prompt whenever you're ready to install."
  exit 0
fi
echo
echo "Install mariadb server and client"
echo "##############################################################"
echo
nala install mariadb-server mariadb-client # Install mariadb server and client
echo
echo

echo "Check the version of mariadb installed now"
echo "##########################################################################"
echo
mariadb --version # Verify if the version intended is installed
echo
echo

echo "Check the version of mysql installed now"
echo "##########################################################################"
echo
mysql --version # Verify if the version intended is installed
echo
echo

echo "Start mariadb to configure it"
echo "##########################################################################"
echo
systemctl status mariadb # Start MariaDB to configure it
echo
echo "Exiting"
exit
