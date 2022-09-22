# zealua
A Zeal plugin written in lua

## commands
### Zeal
### ZealEngine
### ZealFT

## todo
- [ ] ZealEngine
	- asks for docset (completion using \_completion)
	- asks for input (if none given uses <cword>)
- [ ] ZealInstall
	- asks for permission to download from dash servers
	- detects which docset to download using, in order,
		1. user filetype -> filetype defined using ZealFT
		2. filetype -> `vim.bo.filetype`
		3. extension -> `expand('%:e')`
	- fallbacks to user choice in case of multi-matching docsets  
		For example, in sql files, the filetype would be sql.  
		This will match multiple docset -> PostgreSQL, MySQL, SQLite3, ...

