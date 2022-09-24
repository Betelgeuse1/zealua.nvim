package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"

	"github.com/PuerkitoBio/goquery"
)

const (
	GITHUB_REPO_URL string = "https://github.com/Kapeli/feeds"
	LUA_DOCSETS_FILE string = "../lua/zealua/docsets.lua"
)

func main() {
	req, err := http.NewRequest("GET", GITHUB_REPO_URL, nil)
	if err != nil {
		log.Fatal(err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		log.Fatal(err)
	}
	defer resp.Body.Close()

	file := LuaBoilerplateFile()
	defer Finalize(file)

	document, err := goquery.NewDocumentFromReader(resp.Body)
	if err != nil {
		log.Fatal(err)
	}

	document.Find(`a[title$=".xml"]`).Each(func (num int, selection *goquery.Selection) {
		text := selection.Text()
		
		docset := fmt.Sprintf("\t\"%s\",\n", text[:len(text)-4])
		file.WriteString(docset)
	})
}

func LuaBoilerplateFile() *os.File {
	dir, err := os.Getwd()
	if err != nil {
		log.Fatal(err)
	}

	file, err := os.CreateTemp(dir, "lua-docsets-*")
	if err != nil {
		log.Fatal(err)
	}

	_, err = file.WriteString("return {\n")
	if err != nil {
		log.Fatal(err)
	}

	return file
}

func Finalize(file *os.File) {
	_, err := file.WriteString("}")
	if err != nil {
		log.Fatal(err)
	}

	err = file.Close()
	if err != nil {
		log.Fatal(err)
	}

	absPath, err := filepath.Abs(LUA_DOCSETS_FILE)
	if err != nil {
		log.Fatal(err)
	}

	err = os.Rename(file.Name(), absPath)
	if err != nil {
		log.Fatal(err)
	}
}
