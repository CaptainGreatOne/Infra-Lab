package handlers

import (
	"github.com/gin-gonic/gin"
)

func registerRepoRoutes(router *gin.Engine) {
	router.GET("/repo", getRepoInfo)
}

// @Summary     Get repository info
// @Description Returns information about the current repository from Github
// @Tags        repo github repository info 
// @Produce     json
// @Success     200 {object} map[string]string
// @Router      /repo [post]
func getRepoInfo(c *gin.Context) {

} 