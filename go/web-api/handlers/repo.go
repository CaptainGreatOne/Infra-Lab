package handlers

import (
	"github.com/gin-gonic/gin"
)

func registerRepoRoutes(router *gin.Engine) {
	router.GET("/repo", getRepoInfo)
}

func getRepoInfo(c *gin.Context) {
	
} 