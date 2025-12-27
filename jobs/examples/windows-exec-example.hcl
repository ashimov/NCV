job "windows-exec-example" {
  datacenters = ["dc1"]
  type = "service"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "windows"
  }

  group "windows-exec-example" {
    count = 1

    task "windows-exec-example" {
      driver = "raw_exec"
      config {
        command = "C:\Windows\System32\cmd.exe"
        args    = ["/c", "echo hello from windows raw_exec & timeout /t 3600"]
      }
      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
