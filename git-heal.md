# Git Heal

On my local PC, the git repo for this project gets corrupted. This is probably caused due to either improperly shutting the VM down or for some unknmown reason relating to virtualization on my personal, messed up machine. 
To remedy this, I had claude create the `git-heal` script. 
git-heal is meant to be run in the corrupted repo. It determines if the git repo is corrupted, creates a dew folder, initializes the folder for the remote repo, copies project files to the new directory, turns the old directory into a backup, then force pushes all files to the remote repo. This has solved my personal problems, and is being recorded here for the sake of it. 

## Installation: 
in the repo root folder, run the following commands: 
```bash
sudo cp git-heal /usr/local/bin/git-heal
sudo chmod +x /usr/local/bin/git-heal
```

Then, just run the script using the command `git-heal`, and follow any promts. Issue solved. 