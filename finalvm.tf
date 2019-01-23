# Configure the Microsoft Azure Provider

provider "azurerm" {
    subscription_id = "47aecb40-f45d-49a7-a070-7c748616ec94"
    client_id       = "64727e9b-469e-43fe-b859-ce6e872920a2"
    client_secret   = "11a49789-921f-4789-b22b-7d181e5d4ea2"
    tenant_id       = "6ed682dd-ec2d-43d7-a428-1f8b3749f210"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "myResourceGroup"
    location = "eastus"

    tags {
        environment = "Terraform Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    tags {
        environment = "Terraform Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = "${azurerm_resource_group.myterraformgroup.name}"
    virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = "eastus"
    resource_group_name          = "${azurerm_resource_group.myterraformgroup.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "Terraform Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {

    name                      = "myNIC"
        location                  = "eastus"
    resource_group_name       = "${azurerm_resource_group.myterraformgroup.name}"
    network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip.id}"
    }

    tags {
        environment = "Terraform Demo"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.myterraformgroup.name}"
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.myterraformgroup.name}"
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "myVM"
    #name                  = "myVM1${count.index}"
    location              = "eastus"
    resource_group_name   = "${azurerm_resource_group.myterraformgroup.name}"
    network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]
    vm_size               = "Standard_A1_v2"
    #count = 2

    storage_os_disk {
        name              = "myOsDisk"
       # name              = "myOsDisk${count.index}"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        #managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "RedHat"
        offer     = "RHEL"
        sku       = "7.4"
        version   = "7.4.2018010507"
    }
# Optional data disks
    storage_data_disk {
      name          = "data_cdhmanager"
       #name          = "data_cdhmanager${count.index}"
      #vhd_uri       = "${azurerm_storage_account.storage.primary_blob_endpoint}${azurerm_storage_container.container.name}/data_cdhmanager.vhd"
     managed_disk_type = "Standard_LRS"
      disk_size_gb  = "10"
      create_option = "Empty"
      lun           = 0
    }
    os_profile {
        computer_name  = "myvm"
        admin_username = "azureuser"
        #admin_password = "Terraform786"
        # custom_data    = "${data.template_cloudinit_config.config.rendered}"
    }

   os_profile_linux_config {
       disable_password_authentication = true
       ssh_keys {
           path     = "/home/azureuser/.ssh/authorized_keys"
          # key_data = "${file(var.key_path)}"
         key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDG4SkmD4mXRMki3F6RPQwCBGP6tXBmBW4yPBgQDWCmEhju4xcvnQhrbJ0gQxhkduYYKEjMEyK1F1jLuCoLQg+vR40MXH1qOnxGUdenQTS4vapaqdcG1X6++GLXY8tNeSF7yYndGtMfrKKcuiza4RytfA+MmRzC8Ec+n8dMvY3VlYfIizvFYUVJ3yYAyGoQrWfSdSaurICG5Ub+U+GPgk/EtR/lup7g6gTfbD+Chcx0m0dwNXS2DF1ACisDxgJNg6T7vCMIaeHDLa2UvE+2FSyy+PB78JXonbRSxReyuVOnoEOfgyOLYPeimUmE0C2IW9Mh3pp+e1f/H3v9g7ES1LH5 devops@DESKTOP-7TL569B"
        }
    }


tags {
        environment = "Terraform Demo"
    }

}
resource "azurerm_virtual_machine_extension" "myterraformvm" {
  name                 = "myvm"
  location             = "eastus"
  resource_group_name  = "${azurerm_resource_group.myterraformgroup.name}"
  virtual_machine_name = "${azurerm_virtual_machine.myterraformvm.name}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "fileUris": [ "https://raw.githubusercontent.com/devopsraman/puppetrepo/master/puppet.sh" ],
        "commandToExecute": "bash puppet.sh"
    }

SETTINGS

}
