---
slug: asynchronous-dashboard-bash
title: "Modern TUI: Bringing Asynchronicity to Pure Bash"
authors: [arijit1begins]
tags: [tui, bash, distrobox, engineering]
---

We are excited to announce the latest evolution of the DbxSmith Dashboard—a full-featured, asynchronous TUI built entirely in pure Bash.

<!--truncate-->

## The Flicker Problem

Traditional shell-based interfaces often suffer from "The Flicker." Every time the screen updates, it clears the whole terminal, leading to a jarring strobe effect. When we set out to build the DbxSmith dashboard, our first requirement was **zero flicker**.

By leveraging `tput cup` for absolute cursor addressing and managing our own screen buffer logic, we've achieved a rendering engine that feels as smooth as a compiled C application.

## Breaking the Sequential Chain

Bash is inherently sequential. Usually, if you run a command like `distrobox create`, your script waits for it to finish. In a dashboard, this is unacceptable; the UI should never freeze.

Our new **Asynchronous Task Engine** solves this by:
1. Spawning the work process in the background.
2. Using a named pipe (FIFO) to stream logs back to the main UI loop.
3. Using non-blocking `read` with micro-timeouts to poll the pipe while keeping the UI responsive.

The result? You can watch a Fedora container being provisioned in a visual overlay while still scrolling through your existing Ubuntu boxes.

## User-Centric Design

We've focused on the "Quality of Life" details that make a tool a joy to use:
- **Wizard Back-Navigation**: Made a typo on Step 3? Just hit `Esc` to go back to Step 2.
- **Auto-Dismissal**: We don't make you click "OK" when things work. The dashboard knows when it's done and gets out of your way.
- **Zsh & Bash Compatibility**: The dashboard shell function is hardened to work perfectly in both major shells, including native Zsh autocompletion.

## What's Next?

We're looking into expanding the dashboard with real-time resource monitoring (CPU/RAM) for each container and a more customizable theming engine.

Try it out today:
```bash
dbx-smith dash
```
