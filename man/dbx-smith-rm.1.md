<!-- markdownlint-disable MD010 MD036 -->
# NAME

	dbx-smith rm
	dbx-smith-rm

# DESCRIPTION

dbx-smith-rm is the atomic destructor for Distrobox containers and their associated DbxSmith infrastructure. It ensures that when a container is removed, all corresponding artifacts—such as isolated home directories, shell aliases, registry manifests, network bridges, and podman volumes—are cleanly purged from the host system.

# SYNOPSIS

**dbx-smith-rm** [options] <box_name> [box_name_2 ...]

	--help/-h:		show this help message
	--purge/-p:		Deep clean: Purge container, isolated home dir, registry manifest,
				shortcut fragments, isolated network bridges, and internal Podman volumes.

# EXAMPLES

Remove a container and its basic configuration:

	dbx-smith-rm my-alpine

Perform a deep purge of a container, including all volumes and network bridges:

	dbx-smith-rm --purge my-vault
