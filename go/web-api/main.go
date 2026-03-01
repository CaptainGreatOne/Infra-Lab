package main

import (
	_ "github.com/CaptainGreatOne/infra-lab/web-api/docs"
	"github.com/CaptainGreatOne/infra-lab/web-api/handlers"
	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
)

// @title           infra-lab web-api
// @version         1.0
// @description     A REST API built with Go and Gin as part of the infra-lab project.
// @host            localhost:8080
// @BasePath        /
// @leftDelimiter  {{
// @rightDelimiter  }}
func main() {

	router := gin.Default()

	router.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	handlers.RegisterRoutes(router)

	router.Run(":8080")
}
