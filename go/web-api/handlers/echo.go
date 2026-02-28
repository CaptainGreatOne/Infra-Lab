package handlers

import (
	"github.com/gin-gonic/gin"
)

func registerEchoRoutes(router *gin.Engine) {
	router.POST("/echo", postEcho)
}

func postEcho(c *gin.Context) {

	
} 