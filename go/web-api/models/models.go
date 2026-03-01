package models

type HelloWorldResponse struct {
	Message string `json:"message" example:"Hello World!"`
}

type HelloUserResponse struct {
	Message string `json:"message" example:"Hello {User Name Here}}!"`
}

type SystemInfoResponse struct {
	Hostname     string  `json:"hostname"      example:"infra-lab-sister"`
	OS           string  `json:"os"            example:"linux"`
	Architecture string  `json:"architecture"  example:"amd64"`
	CPUCount     int     `json:"cpu_count"     example:"6"`
	GoVersion    string  `json:"go_version"    example:"go1.22.4"`
	MemAllocMB   float64 `json:"mem_alloc_mb"  example:"1.2"`
}
