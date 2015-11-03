
# High-Level outline

the goal of the outline is to try and cover all the aspects without letting the
details break my focus.


- hero project
    - h command
        - extensible
            - add a file to PATH named `h-<subcmd>`
        - project-centric
            - maintains a list of projects and their location
                - adds a binstub to path named after the project that provides a myriad
                  of useful tools
        - provides heroku binstubs for managing different remotes/heroku apps
          confidently and with less typing
        - a command-line note taking system
            - includes tagging and a vim plugin for improved speed
        - command-line task/project management system
            - includes tagging
            - decentralized, good for having the storycards travel with the git repo
        - contains a large array of tips on different topics
            - vim
            - git
            - unix
                - bash
                - zsh
                - readline
            - development
                - design patterns
                - etc.
            - ruby
            - rails
            - osx
        - templates
            - file templates for things like...
                - different types of shell scripts
                    - bash
                    - ruby
                        - ones that accept subcommands
                        - ones that have modules that can be added
                        - ones that are extensible
                - ruby experiments - for testing 1-off ruby ideas
        - all sorts of utilities to:
            - simplify tasks
                - configuring things
                - generate and manage ssh keys
            - fix recurring issues
                - wifi, postgres, etc.
            - correct inconsistencies
                - a regex cmd to use 1 defined regex format, and convert it to any of
                  the various flavors:
                    - vim (has 3 flavors)
                    - sed (2 flavors)
                    - grep (2 (3) flavors)
                    - ag
                    - perl/pcre
                    - etc.
    - vim plugin
        - introduces a new style/set of mappings
        - toggle options
        - adds commands for accessing files quickly with minimal keystrokes




# The Hero Project

A collection of tools, configurations, and tips for improving developer
productivity.

# Overview

Hero is not just one or two commands, there is a whole system and philosophy
behind it.  The following is my best attempt at creating a list of the different
parts.

- A document describing the ideal design/user experience for shell commands
- The hero command `H`
  - `H` is an extensible shell command that provides several tools, each of
    which tackle a wide spectrum of their respective topic

  - `H project` - for adding and managing the list of projects a developer is
    working on with the current machine.
    - like most H subcommands they take ...subcommands
    - `add` - add a new project to the list (name, parent directory of the
      project)
    - `list`
    - other crud actions

    - when a new project is added...it copies the project _binstub_ to a folder
      in `$PATH`
      - the binstub lets the user do many things
      - `<projectname> <subcmd>`
        - `copley tmux` - opens a new tmux session named copley and the basedir
          is set to the copley folder
        - `copley task new` - creates a new task file (todo item) in copley's
          repo (there is an entire system for managing tasks/todo via the
          command-line)
        - `copley deploy`
        - `copley feature start <issueno>`
        - `copley issues` - list github issues for the project
        - `copley mkissue 'descr' labels: refactor todo` - make a new github
          issue for the project
        - `copley server` - start the rails server
        - `copley console` - start the rails console



