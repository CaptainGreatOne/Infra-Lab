package handlers

import "github.com/gin-gonic/gin"

func RegisterRoutes(router *gin.Engine) {
	registerHelloRoutes(router)
	registerSystemRoutes(router)
	registerEchoRoutes(router)
	registerRepoRoutes(router)
}
