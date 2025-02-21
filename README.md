# Stable Diffusion Model Management

## Link-Models

[Link-Models.ps1](/Link-Models.ps1) is a PowerShell script that creates hardlinks from a source directory to one or more target directories as defined in a configuration file. The configuration file (`configuration.json`) specifies the source directory along with an array of target directories, each optionally including subdirectory mappings.

## Example Configuration

The `example_configuration.json` file serves as a template for setting up the directories and mappings. For example:

```json
{
    "sourceDirectory": "E:/Models/source",
    "targetDirectories": [
        {
            "Path": "E:/Models/target1",
            "Mappings": {
                "subdir1": "mappedSubdir1",
                "subdir2": "nil"
            }
        },
        {
            "Path": "E:/Models/target2",
            "Mappings": {}
        }
    ]
}
```

- `sourceDirectory`: The location of the source models.
- `targetDirectories`: An array defining where hardlinks should be created.
  - `Path`: The path of the target directory.
  - `Mappings`: A hashtable mapping subdirectory names from the source to new names in the target directory. A mapping value of `nil` indicates that the corresponding subdirectory should be skipped.
