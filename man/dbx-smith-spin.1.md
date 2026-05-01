<!-- markdownlint-disable MD010 MD036 -->
# NAME

	dbx-smith spin
	dbx-smith-spin

# DESCRIPTION

dbx-smith-spin is the CLI factory and provisioner for the DbxSmith productivity suite. It automates the creation of Distrobox containers using predefined security and isolation strategies. It configures the containers, applies custom UI coloring based on the image, and automatically generates shell aliases and keybindings for quick access.

# SYNOPSIS

**dbx-smith-spin** [options] [strategy] [name] [image] [alias] [bindkey]

	--help/-h:		show this comprehensive help message
	--version/-v:		show the current dbx-smith-spin version

**Strategies:**

	standard:		Frictionless, host-mirrored daily driver environment.
	airgapped:		Zero-network vault with an isolated, private home directory.
	ghost:			Identity obfuscation running as a transient user ('ghostuser').
	isolated-net:		Secure sandbox with a dedicated, host-blind NAT bridge network.
	ghost-airgapped:	Combined: Transient 'ghostuser' identity with zero network.
	ghost-isolated-net:	Combined: Transient 'ghostuser' identity with NAT bridge network.

**Arguments:**

	name:			Unique identifier for your Distrobox container.
	image:			Container image to use (e.g., docker.io/library/alpine).
	alias:			(Optional) Shell alias to bind (e.g., 'vault').
	bindkey:		(Optional) Zsh/Bash hotkey to bind (e.g., '^G').

# EXAMPLES

Provision a standard container with alpine linux:

	dbx-smith-spin standard my-alpine alpine:latest

Provision an airgapped vault container with an alias 'vault' and bindkey '^V':

	dbx-smith-spin airgapped my-vault alpine:latest vault ^V

Provision an isolated-network container for testing:

	dbx-smith-spin isolated-net my-sandbox fedora:latest

Provision a ghost container for transient tasks:

	dbx-smith-spin ghost my-ghost ubuntu:latest

# ENVIRONMENT VARIABLES

	XDG_CONFIG_HOME
	ZSH_VERSION
	BASH_VERSION
