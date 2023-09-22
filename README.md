# Prologue

I'm developing a new version of an application, that I migrated from a `Docker`-based
environment to `NixOS`: using a *flake* I wrapped the `Python` backend logic with `poetry2nix`
and the `JS` frontend with `node2nix`.

I am not a `nix` expert, but with the valuable help of a local *mentor* I was able to
accomplish the task and now I'm almost done: everything works, and I am foreseeing the time to
deploy it into staging for squeezing out remaining issues.

Since I have no precise timings on that, now and then I do some gardening on the whole stack,
mainly to keep its dependencies up-to-date.


# Problem

Recently I refreshed its *flake inputs* as I have done lot of times now and then, and hit a
severe problem, where `nix` uses an **unbound** amount of system memory in its early evaluation
of the *flake*, that basically grinding my local machine to a halt: for some reason the kernel
*OOM* killer did not kick in, and when after a minute or so all the 16Gb of `RAM` and the 8Gb
of swap were exausted I had to manually poweroff the computer.

I isolated the problem to the version of `nixpkgs` referenced in the *flake*: up to a point
everything works as expected (to be precise, revision 33cd48c86b25cef, as of Aug 19 2023),
while beyond that the problem shows up.

Other inputs do not impact, and neither the version of `nix`: on my local machine running
`NixOS` unstable I'm using a fairly recent version of it, `2.17.0`, but even `2.11.1` exhibits
the very same behaviour.


# Investigation

I started by creating a slimmed down repository containing just the strictly needed stuff,
*nix* recipes together with `Python` and `JS` *requirements*. I also commented out some of the
heavy `Python` dependencies to lighten the closure size.

I then verified that the *key* factor that triggers the issue is exactly one, the specific
revision of `nixpkgs` used: referencing a *good* version, the outcome does not change altering
all other factors (version of `nix`, revisions of other *inputs* in particular `poetry2nix`,
making the latter follow or not the outer `nixpkgs`); the same happens referencing a *bad*
version of `nixpkgs`, that is changing other factors always triggers the *out of memory* issue.

At this point I tried to find the *culprit* commit that introduced the problem in `nixpkgs`. I
wrote the following `Bash` script in `/tmp/test-mockhopi.sh`, limiting the virtual memory to
5Gb just to avoid locking the machine:

```bash
#!/usr/bin/env bash

# git bisect start --no-checkout HEAD 33cd48c86b25cef36b092005718738610ad82fd3

NIXPKGS_COMMIT_REF=$(git rev-parse BISECT_HEAD)

echo "CHECKING WITH NIXPKGS@$NIXPKGS_COMMIT_REF ..."

cd /tmp/mockhopi
nix flake lock --override-input nixpkgs github:NixOS/nixpkgs/$NIXPKGS_COMMIT_REF

ulimit -v $((5 * 1024 * 1024))

nix develop --command true |& tee /tmp/mockhopi/nix-develop-output.txt

if grep --silent "error: out of memory" /tmp/mockhopi/nix-develop-output.txt 2>&1
then
    echo "FAILED DUE TO OUT-OF-MEMORY"
    exit 1
else
    echo "ASSUMING GOOD"
    exit 0
fi
```

and executed the following steps:

1.  under `/tmp`, executed `git clone https://github.com/lelit/mockhopi.git` and `git clone
    https://github.com/NixOS/nixpkgs.git`

2.  in `/tmp/mockhopi`, verified that the *good* commit is effectively so:

    ```bash
    $ nix flake lock --override-input nixpkgs github:NixOS/nixpkgs/33cd48c86b25cef36b092005718738610ad82fd3
    $ nix develop --command echo OK
    OK
    ```
        
3.  in `/tmp/mockhopi`, verified that the `HEAD` revision (current as I am writing this) of
    `nixpkgs` is *bad*:
    
    ```
    $ nix flake lock --override-input nixpkgs github:NixOS/nixpkgs/b570cc35e4a3912ffb8c4caf4d8b8c90a8f1de99
    $ ulimit -v $((5 * 1024 * 1024)) # 5Gb
    $ nix develop --command true
    warning: Git tree '/tmp/mockhopi' is dirty
    GC Warning: Failed to expand heap by 16777216 bytes
    ...
    GC Warning: Failed to expand heap by 16777216 bytes
    GC Warning: Failed to expand heap by 262144 bytes
    GC Warning: Out of Memory! Heap size: 4647 MiB. Returning NULL!
    error: out of memory
    ```
    
4.  in `/tmp/nixpkgs`, executed `git bisect start --no-checkout HEAD
    33cd48c86b25cef36b092005718738610ad82fd3`, followed by `git bisect run
    /tmp/test-mockhopi.sh`

5.  armed with patience, I waited for the bisect conclusion:

    ```
    5a9dda28aa00dd88de3329c29bcdae40591d4634 is the first bad commit
    commit 5a9dda28aa00dd88de3329c29bcdae40591d4634
    Author: Theodore Ni <3806110+tjni@users.noreply.github.com>
    Date:   Fri Jul 28 02:26:27 2023 -0700

        python3.pkgs.setuptools: build without bootstrapped-pip

     .../python-modules/setuptools/default.nix          | 66 +++++-----------------
     1 file changed, 14 insertions(+), 52 deletions(-)
    bisect found first bad commit
    ```

# Conclusion

I cannot say whether this is a problem of `nix` itself, or something wrong in `nixpkgs`, or
even a problem in how I wrote my *flake*: since I started developing the new version of my
application (a couple of years ago), I obviously faced (and solved) "problems" introduced by
newer versions of `nix` or `nixpkgs`, or for what matters by newer versions of this and that
dependencies.

This time is different, because as much as I tried to understand and *fix* (or *workaround*)
the issue, I was not able to get any closer to a possible solution.

Any kind of help, be it on how to further investigate or on possible corrections of the
*flake*, will be highly appreciated.
