provider "null" {}

resource "null_resource" "multipass_k3s_master" {
  provisioner "local-exec" {
    command = "multipass launch --name k3s-master --cpus 4 --memory 4G --cloud-init cloud-init.yaml --network Wi-Fi"
  }

  # This ensures that the instance is destroyed when terraform destroy is called
  lifecycle {
    prevent_destroy = false
  }

  # Adding destroy logic
  provisioner "local-exec" {
    when    = destroy
    command = "multipass delete --purge k3s-master"
  }
}

resource "null_resource" "multipass_k3s_worker" {
  provisioner "local-exec" {
    command = "multipass launch --name k3s-worker --cpus 2 --memory 1G --cloud-init cloud-init.yaml --network Wi-Fi"
  }

  # This ensures that the instance is destroyed when terraform destroy is called
  lifecycle {
    prevent_destroy = false
  }

  # Adding destroy logic
  provisioner "local-exec" {
    when    = destroy
    command = "multipass delete --purge k3s-worker"
  }
}

resource "null_resource" "fetch_master_ip" {
  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
        command     = "$json = multipass info k3s-master --format json | ConvertFrom-Json;$ip = $json.info.'k3s-master'.ipv4;\"[k3s_master]`n$ip\" | Out-File '../ansible/inventory/hosts.ini' -Append -Encoding ascii "
  }

  depends_on = [ null_resource.multipass_k3s_master ]

}

resource "null_resource" "fetch_worker_ip" {
  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = "$json = multipass info k3s-worker --format json | ConvertFrom-Json;$ip = $json.info.'k3s-master'.ipv4;\"\n[k3s_worker]`n$ip\" | Out-File '../ansible/inventory/hosts.ini' -Append -Encoding ascii "
  }

  depends_on = [ null_resource.multipass_k3s_worker ]

}

