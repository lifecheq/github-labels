# Create a set of labels on GitHub 

Useful helper to standardize labels across all your projects. 

## Usage

1. Download the script

2. Interactive prompt: 
```
./create-github-labels
```
OR

Silent, if `$GITHUB_TOKEN` is set in environment and repository provided as an argument:
```
./create-github-labels myorg/myrepo
```

## Provided labels
![Screenshot of labels](https://user-images.githubusercontent.com/378794/55607288-87cd5500-57c7-11e9-8df3-bf09a3563eff.png)

An example of the pull request progression through labels:

`DO NOT REVIEW` -> `Needs review` -> `Ready for test` -> `Ready to be merged`

## Modifying labels
You may specify your own labels in the script with name, color and description.
