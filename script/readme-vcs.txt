== Git branches ==
1. Develop:  Adding new features
2. Beta:     Working version of Develop
3. Testing:  Long-term testing
4. Config:   Update config file only
5. Master:   Stable version

== Inclusing Relation among branches ==
 Develop > Beta > Tesging > Config > Master

== Operation ==
1. Develop:  Add new feature/format change anytime.
2. Beta:     Bugfix only and Short Test on the actual operation.
3. Testing:  Looks Stable. Use on the actual operation.
4. Config:  Update Config file only.
5. Master:  Most reliable version. Get back here anytime failure.

==Rules for Commit Message=
1. Small project name (i.e. using ox)
   If it is part of big changes.
2. Category
 a. Format changes on config/status files
   (In case of breaking backward compatibilities of data)
   Format Change: XML Schema, JSON, SQL

 b. Changes in logical structures. (by inspecting rubocop)
  Add: Adding a new class, func, vars
  Split: Splitting features of Class/methods.
  Bugfix: Fix bugs.

 c. No canges in logical structures.
  Refactoring: Name changes, func name changes.
               Auto formatting by using rubocop.
  Update: Comment, Config files (No format Changes), Document files
  New: Creating new files.

3. Where? (filename: +)
 a. Class/Module names
    Class#func() or Class@var, etc
 b. XML (Xpath)
 c. JS/HTML
 d. text files

4. Description.
