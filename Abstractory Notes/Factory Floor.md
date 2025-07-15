


# Resetting to pre-run
* Copies of assemblies are stored in `starting_assemblies`, and reset to that.
	* Must be freed to avoid memory leak, because they're nodes not in the tree. The function `_notification()` is used for that, because that can run just before deletion