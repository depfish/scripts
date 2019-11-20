package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
)


func main() {
	GitlabURL := flag.String("host", "https://gitlab-ncsa.ubisoft.org", "gitlab URL, eg.,https://xxx.com")
	SrcProjectID := flag.String("srcID", "", "source Gitlab project ID")
	DestProjectID := flag.String("destID", "", "destnation Gitlab project ID")
	Token := flag.String("token", "", "Gitlab user token")
	flag.Parse()
	if len(*SrcProjectID)==0 || len(*DestProjectID)==0 || len(*Token) ==0{
		fmt.Println("please use -h to check the usage")
		os.Exit(0)
	}
	GitlabAPI := *GitlabURL + "/api/v4/projects/" + *SrcProjectID + "/variables?per_page=10000"
	res := GetGitlabCiEnv(GitlabAPI,*Token)
	if len(res) == 0 {
		os.Exit(100)
	}
	GitlabAPI = *GitlabURL + "/api/v4/projects/" + *DestProjectID + "/variables?per_page=10000"

	PostGitlabCiEnv(res,GitlabAPI,*Token)


}

type GitlabEnv struct {
	VariableType     string `json:"variable_type"`
	Key              string `json:"key"`
	Value            string `json:"value"`
	Protected        bool   `json:"protected"`
	Masked           bool   `json:"masked"`
	EnvironmentScope string `json:"environment_scope"`
}

func PostGitlabCiEnv(payload string,GitlabAPI string, Token string) {
	var envs []GitlabEnv
	err := json.Unmarshal([]byte(payload), &envs)

	if err != nil {
		panic(err)
	}

	for _, env := range envs {
		post := GitlabEnv{
			VariableType:     env.VariableType,
			Key:              env.Key,
			Value:            env.Value,
			Protected:        env.Protected,
			Masked:           env.Masked,
			EnvironmentScope: env.EnvironmentScope,
		}
		data, err := json.Marshal(post)
		if err != nil {
			errors.New("struct to json failed")
		}
		req, err := http.NewRequest("POST", GitlabAPI, bytes.NewBuffer(data))
		req.Header.Set("PRIVATE-TOKEN", Token)
		req.Header.Set("Content-Type", "application/json")
		client := &http.Client{}
		resp, err := client.Do(req)
		if err != nil {
			panic(err)
		}
		body, _ := ioutil.ReadAll(resp.Body)
		fmt.Printf("POST: %v status: %v resp: %v \n",post.Key,resp.Status,string([]byte(body)))
	}

}

func GetGitlabCiEnv(GitlabAPI string, Token string) string {
	req, err := http.NewRequest("GET", GitlabAPI, nil)
	req.Header.Set("PRIVATE-TOKEN", Token)
	req.Header.Set("Content-Type", "application/json")
	client := &http.Client{}
	resp, err := client.Do(req)
	defer resp.Body.Close()

	if err != nil {
		panic(err)
	}
	body, _ := ioutil.ReadAll(resp.Body)
	return string([]byte(body))

}
