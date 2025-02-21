# Stable Diffusion Model Management

## Link-Models

`Link-Models.ps1` is designed to create hardlinks for files from a source directory to multiple target directories based on a configuration file. The configuration file, `configuration.json`, specifies the source directory and a list of target directories with optional subdirectory mappings.

## Example Configuration

The `example_configuration.json` file provides a template for configuring the source and target directories for the model management script. Below is an example of what the configuration file might look like:

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

- `sourceDirectory`: The directory where the source models are located.
- `targetDirectories`: An array of target directories where hardlinks will be created.
  - `Path`: The path to the target directory.
  - `Mappings`: A hashtable that maps subdirectory names in the source directory to new names in the target directory. If a subdirectory should be skipped, it can be mapped to `nil`.
