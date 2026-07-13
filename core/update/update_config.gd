class_name UpdateConfig
extends RefCounted
## Where the game looks for updates. One place to configure distribution.
##
## The updater queries the GitHub Releases API for OWNER/REPO. To ship updates
## to a friend you (1) create the public repo, (2) set REPO below, (3) run
## tools/release/release.ps1 to publish a new release. Their game's
## "Check for Updates" button then sees it.
##
## Until REPO is filled in, the updater reports "not configured yet" instead of
## making a doomed network call — so the button behaves sanely pre-launch.

const GITHUB_OWNER := "slinnerb"

## GitHub repository name. EMPTY until the public repo is created.
## Set this to the repo name (e.g. "reincarnation-roguelike").
const GITHUB_REPO := "garak-parker-bj"


static func is_configured() -> bool:
	return not GITHUB_OWNER.is_empty() and not GITHUB_REPO.is_empty()


## The "latest release" API endpoint for this repo.
static func latest_release_url() -> String:
	return "https://api.github.com/repos/%s/%s/releases/latest" % [GITHUB_OWNER, GITHUB_REPO]


## Human-facing releases page (where the download button sends the player).
static func releases_page_url() -> String:
	return "https://github.com/%s/%s/releases" % [GITHUB_OWNER, GITHUB_REPO]
