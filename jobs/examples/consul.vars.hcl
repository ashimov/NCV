datacenters = ["dc1"]
count = 1
cpu = 500
memory = 512
http_port = 8500

# Example args for DEV mode only. Replace with production config.
task_args = ["agent", "-dev", "-client=0.0.0.0", "-ui"]
