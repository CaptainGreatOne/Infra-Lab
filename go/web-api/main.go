package main

import(
	"github.com/CaptainGreatOne/infra-lab/web-api/handlers"
	"github.com/gin-gonic/gin"
)

func main() {

	router := gin.Default()

	handlers.RegisterRoutes(router)

	router.Run(":8080")
}