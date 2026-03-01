package handlers

import (
	"net/http"

	"github.com/CaptainGreatOne/infra-lab/web-api/models"
	"github.com/gin-gonic/gin"
)

func registerHelloRoutes(router *gin.Engine) {
	router.GET("/helloWorld", getHelloWorld)
	router.GET("/helloUser", getHelloName)
}

// @Summary     Hello World
// @Description Returns a "Hello World" greeting message
// @Tags        Hello
// @Produce     json
// @Success     200 {object} models.HelloWorldResponse
// @Router      /helloWorld [get]
func getHelloWorld(c *gin.Context) {
	c.JSON(http.StatusOK, models.HelloWorldResponse{
		Message: "Hello World!",
	})
}

// @Summary     Hello User
// @Description Returns a dynamic greeting message
// @Tags        Hello
// @Param 	 name query string false "Name of the user to greet"
// @Produce     json
// @Success     200 {object} models.HelloUserResponse
// @Router      /helloUser [get]
func getHelloName(c *gin.Context) {
	name := c.Query("name")
	if name == "" || name == "%20" {
		c.JSON(http.StatusOK, models.HelloUserResponse{
			Message: "Hello Guest!",
		})
		return
	}
	c.JSON(http.StatusOK, models.HelloUserResponse{
		Message: "Hello " + name + "!",
	})

}
