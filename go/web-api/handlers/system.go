package handlers

import (
	"github.com/gin-gonic/gin"
)

func registerSystemRoutes(router *gin.Engine) {
	router.GET("/system", getSystemInfo)
}

func getSystemInfo(c *gin.Context) {

}
