job "dns" {
    datacenters = ["dc1"]
    type = "service"

    group "dns" {

        network {
            port "blocky_http" { to = 4000 }
            port "blocky_dns" { to = 53 }
        }

        restart {
            attempts = 3
            delay    = "20s"
            mode     = "delay"
        }

        task "blocky" {
            driver = "podman"

            artifact {
                source = "https://raw.githubusercontent.com/ArdRay/services/master/files/dns.yml"
                destination = "local/dns.yml"
                mode = "file"
            }

            config {
                image = "docker.io/spx01/blocky"
                args = [
                    "--storage.tsdb.path=/etc/prometheus/data",
                    "--config.file=/etc/prometheus/config/prometheus.yml"
                ]
                force_pull = true
                readonly_rootfs = true
                volumes = [
                    "local/dns.yml:/app/config.yml:ro,noexec"
                ]

                labels = {
                    "service_type" = "services",
                    "service_name" = "dns" 
                }

                logging {
                    driver = "journald"
                    options = [
                        {
                            tag = "DNS"
                        }
                    ]
                }

                ports = [
                    "blocky_http", 
                    "blocky_dns"
                ]
            }

            service {
                name = "blocky"
                tags = [
                    "services"
                ]
                port = "blocky_http"


                check {
                    type = "http"
                    path = "/"
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
                cpu    = 200
                memory = 150
            }

        }
    }
}