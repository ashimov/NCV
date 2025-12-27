job "exec-example" {
  datacenters = ["dc1"]
  type = "service"

  group "exec-example" {
    count = 1

    task "exec-example" {
      driver = "raw_exec"
      config {
        command = "/bin/sh"
        args    = ["-c", "echo hello from raw_exec; sleep 3600"]
      }
      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
