# Configure the Docker provider

variable "db_env" {
  type = "map"
}

provider "docker" {
  host = "tcp://localhost:2376/"
  ca_material = "${file(pathexpand("~/.docker/ca.crt"))}"
  cert_material = "${file(pathexpand("~/.docker/client.pem"))}"
  key_material = "${file(pathexpand("~/.docker/client.key"))}"
}

resource "docker_container" "wp_1" {
  depends_on = [ "docker_container.mysql_1" ]
  image = "${docker_image.wp.latest}"
  name  = "wp_1"
  networks = [
    "${docker_network.wordpress_network.id}"
  ]
  ports {
    internal = 80
    external = 8080
  }
  env = [
    "WORDPRESS_DB_HOST=${docker_container.mysql_1.name}",
    "WORDPRESS_DB_NAME=${var.db_env["db_name"]}",
    "WORDPRESS_DB_USER=${var.db_env["db_user"]}",
    "WORDPRESS_DB_PASSWORD=${var.db_env["db_user_pw"]}"
  ]
}

resource "docker_container" "mysql_1" {
  image = "${docker_image.mysql.latest}"
  name  = "mysql_1"
  networks = [
    "${docker_network.wordpress_network.id}"
  ]
  command = [ "--default-authentication-plugin=mysql_native_password" ]
  volumes {
    volume_name = "${docker_volume.mysql.name}"
    container_path = "/var/lib/mysql"
  }

  env = [
    "MYSQL_ROOT_PASSWORD=${var.db_env["root_pw"]}",
    "MYSQL_DATABASE=${var.db_env["db_name"]}",
    "MYSQL_USER=${var.db_env["db_user"]}",
    "MYSQL_PASSWORD=${var.db_env["db_user_pw"]}"
  ]
  healthcheck {
    test = [
      "mysqladmin",
      "ping"
    ]
    interval = "5s"
    timeout = "1s"
    start_period = "10s"
    retries = 5
  }
}

resource "docker_image" "wp" {
  name = "wordpress:php7.1"
}

resource "docker_image" "mysql" {
  name = "mysql:8"
}

resource "docker_volume" "mysql" {
  name = "data"
}

resource "docker_network" "wordpress_network" {
  name = "wp_network"
}
