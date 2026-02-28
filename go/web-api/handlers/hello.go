package handlers

import (
	"net/http"
	"github.com/gin-gonic/gin"
)

func registerHelloRoutes(router *gin.Engine) {
	router.GET("/hello", getHelloWorld)
	router.GET("/hello/:name", getHelloName)
}

func getHelloWorld(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "Hello World!",
	})
}



func getHelloName(c *gin.Context) {

}
