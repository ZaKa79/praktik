#Edit so it fits current netvork

# 1-Define Terraform Provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}
provider "azurerm" {
  features {}
}

# Remove resource creation for Virtual Network and Subnet

# Update other resources to use the existing virtual network and subnet

# 5-Create Public IP for VM
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = "NorthEurope"
    resource_group_name          = "SAPBasis"  # Update to existing resource group name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}
# 6-Create NSG
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "NorthEurope"
    resource_group_name = "SAPBasis"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Terraform Demo"
    }
}
# 7-Create VNet Interface Card
resource "azurerm_network_interface" "myterraformnic" {
    name                        = "myNIC"
    location                    = "NorthEurope"
    resource_group_name         = "SAPBasis"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "/subscriptions/a7cafe39-c1ce-4310-8cf0-767ea2405209/resourceGroups/SAPBasis/providers/Microsoft.Network/virtualNetworks/BasisNet/subnets/BasisNet"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
    network_interface_id      = azurerm_network_interface.myterraformnic.id
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}
# 8-Create Storage for Boot Diagnostics
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "SAPBasis"
    }

    byte_length = 8
}
# 9-Create Storage Account
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "SAPBasis"
    location                    = "NorthEurope"
    account_replication_type    = "LRS"
    account_tier                = "Standard"

    tags = {
        environment = "Terraform Demo"
    }
}
# 11-Create Virtual Linux Machine
resource "azurerm_linux_virtual_machine" "myterraformvm" {
    name                  = "TerraformBox"
    location              = "NorthEurope"
    resource_group_name   = "SAPBasis"  # Update to existing resource group name
    network_interface_ids = [azurerm_network_interface.myterraformnic.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "TerraformBox"
    admin_username = "saunte"
    disable_password_authentication = false  # Enable password authentication

    admin_password = "ThisIsNotTheRightP@ssWord"  # Set your desired password here

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "Terraform Demo"
    }
}
