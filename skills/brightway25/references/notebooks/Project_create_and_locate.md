# Notebook setup — Projects and where data lives

Creating projects, finding them on disk, moving the storage location.

**Assumes:** Nothing.

This file carries the actual code from the notebook, so you can answer questions,
adapt the patterns, and debug without the notebook being open.

---

## What trips people up

**Uses the legacy `import brightway2 as bw`**  
The only notebook in the folder that does. Notebooks 0–8 use `bw2data as bd` / `bw2calc as bc`. Expect confusion when comparing. Meet people where they are, but flag the mismatch.

**`BRIGHTWAY2_DIR` must be set *before* importing Brightway**  
After the import is too late, and changing it mid-session needs a kernel restart. Symptom: "my projects disappeared" — they did not, Brightway is looking elsewhere. Check `bd.projects.dir`.

**The directory must already exist**  
Pointing `BRIGHTWAY2_DIR` at a non-existent path raises `OSError`, not a helpful message.

**Synced folders corrupt projects**  
Dropbox/OneDrive/iCloud plus SQLite is a bad combination. `bw.config.p['lockable'] = True` helps but does not fully solve it. Better: keep projects outside synced folders.

---

## The notebook, cell by cell

### Create and locate a brightway project

In Brightway, a project is made of three databases: an inventory database, a biosphere database (with elementary flows and natural compartments) as well as an optional impacts characterization database.

Contrary to many LCA sofltware, each project is independent and has its own databases. Hence, they can easiy be used by different brigthway installations.

This creates an empty project in your default anaconda environment

```python
import brightway2 as bw

#bw.projects.create_project('a_dummy_project')
```

Your project is created, but you're not yet inside it. This will get you into your project.

```python
bw.projects.set_current('a_dummy_project')
```

You can check at anytime in which project you're in like so.

```python
bw.projects.current
```

You can also check all the projects that are installed on your computer, like below. It returns a list of projects, the number of databases in each projects, and their size (in GB).

```python
bw.projects.report()
```

Here you can check where the project you created is physically stored on your computer.

```python
bw.projects.output_dir # Not very convenient to find.
```

And here you can ask to get a list of databases your project contains.

```python
bw.databases
```

Which returns an empty list of databases, and that's normal since we have not imported any databases into the project.

We can now try to create a project in a more convenient location. In this case, in a Dropbox folder.

For this, we need to specify the path of the project we want to create/access before we load the brightway package.

You may need however to restart this notebook (kernel -> restart) so as to unload the brightway package.

```python
import os # allows to access directories

mynewdirectory = "/Users/massimo/Documents/Databases/BWprojects" # I want to place the project here
```

```python
os.environ['BRIGHTWAY2_DIR'] = mynewdirectory # sets the bw project in the new directory
```

```python
import brightway2 as bw # Usual import of brightway

bw.projects.set_current('a_dummy_project') # create/load the project
```

We can now check that, indeed, your prject folder is now stored within the dropbox folder "Example_folder".

```python
bw.projects.output_dir
```

When sharing a common project folder on a syncing service like Dropbox, you need to make sure that only one user is allowed to write in the project at any given time, otherwise the database may end up corrupted. To do so, you can add the line below. This line access the configuration pickle (what's a [pickle](https://pythontips.com/2013/08/02/what-is-pickle-in-python/)?) of your project (each project has a configuration pickle).

If one user is working within the project, the other users will be allowed to "read" (access and see data and results), but not modify. Once the user exits the project, the other users will be allowed to write int he project.

```python
bw.config.p['lockable'] = True
```

And finally, we can delete our project.

```python
bw.projects.delete_project("a_dummy_project", delete_dir=True)
```

If you do not specify a name in bw.projects.delete_project(), the currently active project is deleted. If you specify delete_dir=False, only the porject name is deleted, but the data remains.

Right now, the project "a_dummy_project" is not listed anymore in my directory. Note that the project called "default" is always created when specifying a new location for project storing.

```python
bw.projects
```

```python
bw.projects.report()
```
