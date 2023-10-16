variable "repo" {
  type    = string
  default = "ubuntu"
}

variable "tag" {
  type    = string
  default = "jammy"
}

variable "dockerhub_login" {
  type    = string
  default = "${env("DOCKERHUB_LOGIN")}"
}

variable "dockerhub_password" {
  type    = string
  default = "${env("DOCKERHUB_PASSWORD")}"
}

variable "imagedata_file" {
  type    = string
  default = "/imagegeneration/imagedata.json"
}

variable "image_os" {
  type    = string
  default = "ubuntu22"
}

variable "image_version" {
  type    = string
  default = "dev"
}

variable "helper_script_folder" {
  type    = string
  default = "/imagegeneration/helpers"
}

variable "image_folder" {
  type    = string
  default = "/imagegeneration"
}

variable "installer_script_folder" {
  type    = string
  default = "/imagegeneration/installers"
}

packer {
  required_plugins {
    docker = {
      version = ">= 0.0.7"
      source  = "github.com/hashicorp/docker"
    }
  }
}

source "docker" "build_image" {
  image  = "${var.repo}:${var.tag}"
  commit = true
  changes = [
    "ENTRYPOINT /bin/bash"
  ]
}

build {
  name = "ubuntu2204:latest"
  sources = [
    "source.docker.build_image"
  ]

  provisioner "shell" {
    execute_command = "sh -c '{{ .Vars }} {{ .Path }}'"
    inline          = ["apt-get update && apt-get install -y lsb-release wget"]
  }

  provisioner "shell" {
    execute_command = "sh -c '{{ .Vars }} {{ .Path }}'"
    inline          = ["mkdir /etc/cloud/templates"]
  }

  provisioner "shell" {
    execute_command = "sh -c '{{ .Vars }} {{ .Path }}'"
    inline          = ["mkdir ${var.image_folder}", "chmod 777 ${var.image_folder}"]
  }

  provisioner "shell" {
    execute_command = "sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "${path.root}/scripts/base/apt-mock.sh"
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    execute_command  = "sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/base/repos.sh"]
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    execute_command  = "sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/base/apt-ubuntu-archive.sh"]
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    execute_command  = "sh -c '{{ .Vars }} {{ .Path }}'"
    script           = "${path.root}/scripts/base/apt-docker.sh"
  }

  provisioner "shell" {
    execute_command = "sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "${path.root}/scripts/base/limits.sh"
  }

  provisioner "file" {
    destination = "${var.helper_script_folder}"
    source      = "${path.root}/scripts/helpers"
  }

  provisioner "file" {
    destination = "${var.installer_script_folder}"
    source      = "${path.root}/scripts/installers"
  }

  provisioner "file" {
    destination = "${var.image_folder}"
    source      = "${path.root}/post-generation"
  }

  provisioner "file" {
    destination = "${var.image_folder}"
    source      = "${path.root}/scripts/tests"
  }

  provisioner "file" {
    destination = "${var.image_folder}"
    source      = "${path.root}/scripts/SoftwareReport"
  }

  provisioner "file" {
    destination = "${var.image_folder}/SoftwareReport/"
    source      = "${path.root}/../../helpers/software-report-base"
  }

  provisioner "file" {
    destination = "${var.installer_script_folder}/toolset.json"
    source      = "${path.root}/toolsets/toolset-2204-docker.json"
  }

  provisioner "shell" {
    environment_vars = ["IMAGE_VERSION=${var.image_version}", "IMAGEDATA_FILE=${var.imagedata_file}"]
    execute_command  = "sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/installers/preimagedata.sh"]
  }

  provisioner "shell" {
    environment_vars = ["IMAGE_VERSION=${var.image_version}", "IMAGE_OS=${var.image_os}", "HELPER_SCRIPTS=${var.helper_script_folder}"]
    execute_command  = "sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/installers/configure-environment-docker.sh"]
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive", "HELPER_SCRIPTS=${var.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}"]
    execute_command  = "sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/installers/apt-vital.sh"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}"]
    execute_command  = "sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/installers/complete-snap-setup-docker.sh", "${path.root}/scripts/installers/powershellcore.sh"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}"]
    execute_command  = "sh -c '{{ .Vars }} pwsh -f {{ .Path }}'"
    scripts          = ["${path.root}/scripts/installers/Install-PowerShellModules.ps1", "${path.root}/scripts/installers/Install-AzureModules.ps1"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}", "DEBIAN_FRONTEND=noninteractive"]
    execute_command  = "sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = [
                        "${path.root}/scripts/installers/action-archive-cache-docker.sh",
                        "${path.root}/scripts/installers/apt-common.sh",
                        "${path.root}/scripts/installers/azcopy.sh",
                        "${path.root}/scripts/installers/azure-cli.sh",
                        "${path.root}/scripts/installers/azure-devops-cli.sh",
                        "${path.root}/scripts/installers/bicep.sh",
                        "${path.root}/scripts/installers/aliyun-cli.sh",
                        // Has systemctl commands
                        // "${path.root}/scripts/installers/apache.sh",
                        "${path.root}/scripts/installers/aws.sh",
                        "${path.root}/scripts/installers/clang.sh",
                        "${path.root}/scripts/installers/swift.sh",
                        "${path.root}/scripts/installers/cmake.sh",
                        "${path.root}/scripts/installers/codeql-bundle.sh",
                        "${path.root}/scripts/installers/containers.sh",
                        // rsync adds a / before ./ and then fails on no such directory
                        "${path.root}/scripts/installers/dotnetcore-sdk.sh",
                        "${path.root}/scripts/installers/firefox.sh",
                        "${path.root}/scripts/installers/microsoft-edge.sh",
                        "${path.root}/scripts/installers/gcc.sh",
                        "${path.root}/scripts/installers/gfortran.sh",
                        "${path.root}/scripts/installers/git.sh",
                        "${path.root}/scripts/installers/github-cli.sh",
                        "${path.root}/scripts/installers/google-chrome.sh",
                        "${path.root}/scripts/installers/google-cloud-cli.sh",
                        "${path.root}/scripts/installers/haskell-docker.sh",
                        "${path.root}/scripts/installers/heroku.sh",
                        // Problems with repository, sometimes the download fails, different package version every time.
                        "${path.root}/scripts/installers/java-tools-docker.sh",
                        "${path.root}/scripts/installers/kubernetes-tools.sh",
                        "${path.root}/scripts/installers/oc.sh",
                        // Depends on Java
                        "${path.root}/scripts/installers/leiningen.sh",
                        "${path.root}/scripts/installers/miniconda.sh",
                        // Depends on DotNet
                        "${path.root}/scripts/installers/mono-docker.sh",
                        // Depends on Java
                        "${path.root}/scripts/installers/kotlin.sh",
                        // Has systemctl commands
                        // "${path.root}/scripts/installers/mysql.sh",
                        // "${path.root}/scripts/installers/mssql-cmd-tools.sh",
                        // "${path.root}/scripts/installers/sqlpackage.sh",
                        // Has systemctl commands
                        // "${path.root}/scripts/installers/nginx.sh",
                        "${path.root}/scripts/installers/nvm.sh",
                        "${path.root}/scripts/installers/nodejs-docker.sh",
                        "${path.root}/scripts/installers/bazel-docker.sh",
                        "${path.root}/scripts/installers/oras-cli.sh",
                        "${path.root}/scripts/installers/php-docker.sh",
                        // Has systemctl commands
                        // "${path.root}/scripts/installers/postgresql.sh",
                        "${path.root}/scripts/installers/pulumi.sh",
                        "${path.root}/scripts/installers/ruby.sh",
                        "${path.root}/scripts/installers/r.sh",
                        "${path.root}/scripts/installers/rust-docker.sh",
                        "${path.root}/scripts/installers/julia.sh",
                        "${path.root}/scripts/installers/sbt.sh",
                        // Depends on Java?
                        "${path.root}/scripts/installers/selenium.sh",
                        "${path.root}/scripts/installers/terraform.sh",
                        "${path.root}/scripts/installers/packer.sh",
                        "${path.root}/scripts/installers/vcpkg.sh",
                        "${path.root}/scripts/installers/dpkg-config.sh",
                        "${path.root}/scripts/installers/yq.sh",
                        // Failed for some reason
                        "${path.root}/scripts/installers/android-docker.sh",
                        "${path.root}/scripts/installers/pypy.sh",
                        "${path.root}/scripts/installers/python-docker.sh",
                        "${path.root}/scripts/installers/zstd.sh"
                        ]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}", "DOCKERHUB_LOGIN=${var.dockerhub_login}", "DOCKERHUB_PASSWORD=${var.dockerhub_password}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/installers/docker-compose.sh", "${path.root}/scripts/installers/docker-docker.sh"]
  }

  // Problems with Configure-Toolset
  // provisioner "shell" {
  //   environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}"]
  //   execute_command  = "sh -c '{{ .Vars }} pwsh -f {{ .Path }}'"
  //   scripts          = ["${path.root}/scripts/installers/Install-Toolset-docker.ps1", "${path.root}/scripts/installers/Configure-Toolset.ps1"]
  // }

  // Never tested
  // provisioner "shell" {
  //   environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}"]
  //   execute_command  = "sh -c '{{ .Vars }} {{ .Path }}'"
  //   scripts          = ["${path.root}/scripts/installers/pipx-packages.sh"]
  // }

  // Never tested
  // provisioner "shell" {
  //   environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}", "DEBIAN_FRONTEND=noninteractive", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}"]
  //   execute_command  = "/bin/sh -c '{{ .Vars }} {{ .Path }}'"
  //   scripts          = ["${path.root}/scripts/installers/homebrew-docker.sh"]
  // }

  // N/A for docker image
  // provisioner "shell" {
  //   execute_command = "sh -c '{{ .Vars }} {{ .Path }}'"
  //   script          = "${path.root}/scripts/base/snap.sh"
  // }

  // N/A for docker image
  // provisioner "shell" {
  //   execute_command   = "/bin/sh -c '{{ .Vars }} {{ .Path }}'"
  //   expect_disconnect = true
  //   scripts           = ["${path.root}/scripts/base/reboot.sh"]
  // }

  provisioner "shell" {
    execute_command     = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    pause_before        = "1m0s"
    scripts             = ["${path.root}/scripts/installers/cleanup.sh"]
    start_retry_timeout = "10m"
  }

  provisioner "shell" {
    execute_command = "sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "${path.root}/scripts/base/apt-mock-remove-docker.sh"
  }

  provisioner "shell" {
    environment_vars = ["IMAGE_VERSION=${var.image_version}", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}"]
    inline           = ["pwsh -File ${var.image_folder}/SoftwareReport/SoftwareReport.Generator.ps1 -OutputDirectory ${var.image_folder}", "pwsh -File ${var.image_folder}/tests/RunAll-Tests.ps1 -OutputDirectory ${var.image_folder}"]
  }

  provisioner "file" {
    destination = "${path.root}/Ubuntu2204-Readme.md"
    direction   = "download"
    source      = "${var.image_folder}/software-report.md"
  }

  provisioner "file" {
    destination = "${path.root}/software-report.json"
    direction   = "download"
    source      = "${var.image_folder}/software-report.json"
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPT_FOLDER=${var.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}", "IMAGE_FOLDER=${var.image_folder}"]
    execute_command  = "sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/installers/post-deployment.sh"]
  }

  // provisioner "shell" {
  //   environment_vars = ["RUN_VALIDATION=${var.run_validation_diskspace}"]
  //   scripts          = ["${path.root}/scripts/installers/validate-disk-space.sh"]
  // }

  // provisioner "file" {
  //   destination = "/tmp/"
  //   source      = "${path.root}/config/ubuntu2204.conf"
  // }

  // provisioner "shell" {
  //   execute_command = "sh -c '{{ .Vars }} {{ .Path }}'"
  //   inline          = ["mkdir -p /etc/vsts", "cp /tmp/ubuntu2204.conf /etc/vsts/machine_instance.conf"]
  // }

  // provisioner "shell" {
  //   execute_command = "sh -c '{{ .Vars }} {{ .Path }}'"
  //   inline          = ["sleep 30", "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"]
  // }
}
