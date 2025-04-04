# git Cheat Sheet

## Listing files

List ignored files:
```bash
git status --ignored     # Modern way
git check-ignore -- *       # List all ignored files
git check-ignore -v -- *    # List all ignored files and show the rule that is
                            # reponsible.
```

List tracked files:
```bash
git ls-tree --name-only -r HEAD   # list all files from here
git ls-tree --full-tree --name-only -r HEAD  # list all files from git root
```

## Delete branch

When an experimental branch is merge or ready to delete

```bash
git branch -D my-experiment
```

## Squashing

Squashing is done during a rebase. 

```bash
git rebase -i HEAD~3
```

## Merge base

Show common root of two divering branches

```bash
git merge-base commit1 commit2
```

