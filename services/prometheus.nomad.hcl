job "monitoring" {
    datacenters = ["dc1"]
    type = "service"

    group "prometheus" {

        network {
            port "prometheus_ui" { 
                static = 9090 
                to     = 9090
            }
        }

        restart {
            attempts = 3
            delay    = "20s"
            mode     = "delay"
        }

        task "prometheus" {
            driver = "podman"

            artifact {
                source = "https://raw.githubusercontent.com/ArdRay/services/master/files/prometheus.yml"
                destination = "local/prometheus.yml"
                mode = "file"
            }

            config {
                image = "docker.io/prom/prometheus"
                args = [
                    "--storage.tsdb.path=/etc/prometheus/data",
                    "--config.file=local/prometheus.yml"
                ]
                force_pull = true
                readonly_rootfs = true
                volumes = [
                    "/mnt/prometheus_service:/etc/prometheus"
                ]

                labels = {
                    "service_type" = "monitoring",
                    "service_name" = "prometheus" 
                }

                logging {
                    driver = "journald"
                    options = [
                        {
                            tag = "PROMETHEUS"
                        }
                    ]
                }

                ports = ["prometheus_ui"]
            }

            service {
                name = "prometheus"
                tags = [
                    "metrics"
                ]
                port = "prometheus_ui"


                check {
                    type = "http"
                    path = "/-/healthy"
                    interval = "10s"
                    timeout = "2s"

                    success_before_passing   = "3"
                    failures_before_critical = "3"

                    check_restart {
                        limit = 3
                        grace = "60s"
                    }
                }
            }

            resources {
                cpu    = 50
                memory = 100
            }

        }
    }
}